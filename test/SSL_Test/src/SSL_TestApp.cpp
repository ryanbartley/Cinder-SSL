#include "cinder/app/App.h"
#include "cinder/app/RendererGl.h"
#include "cinder/gl/gl.h"
#include "cinder/Utilities.h"

#include "asio/asio.hpp"
#include <asio/ssl.hpp>

#include <algorithm>
#include <atomic>
#include <cstdlib>
#include <ctime>
#include <iostream>
#include <memory>
#include <thread>
#include <vector>

class IoServices {
public:
	IoServices(std::size_t number)
	: m_ioServices(number)
	{
		for (auto &ioService : m_ioServices) {
			m_idleWorks.emplace_back(ioService);
			m_threads.emplace_back([&] { ioService.run(); });
		}
	}
	
	void stop()
	{
		for (auto &ioService : m_ioServices)
			ioService.stop();
		
		for (auto &thread : m_threads)
			if (thread.joinable())
				thread.join();
	}
	
	~IoServices() { stop(); }
	
	asio::io_service &get()
	{
		return m_ioServices[(m_nextService++ % m_ioServices.size())];
	}
	
private:
	std::atomic<std::size_t> m_nextService{0};
	std::vector<asio::io_service> m_ioServices;
	std::vector<asio::io_service::work> m_idleWorks;
	std::vector<std::thread> m_threads;
};

class ServerConnection {
public:
	ServerConnection(asio::io_service &ioService, asio::ssl::context &context,
					 std::size_t messageSize)
	: m_socket{ioService, context}
	, m_buffer(messageSize)
	{
		++s_runningConnections;
	}
	
	~ServerConnection() { --s_runningConnections; }
	
	asio::ssl::stream<asio::ip::tcp::socket>::lowest_layer_type &socket()
	{
		return m_socket.lowest_layer();
	}
	
	void start(std::shared_ptr<ServerConnection> self, std::size_t messages)
	{
		m_socket.async_handshake(asio::ssl::stream_base::server,
								 [=](const asio::error_code &) { asyncRead(self, messages); });
	}
	
	static std::size_t runningConnections() { return s_runningConnections; }
	
private:
	void asyncRead(std::shared_ptr<ServerConnection> self, std::size_t messages)
	{
		asio::async_read(m_socket, asio::buffer(m_buffer),
						 [=](const asio::error_code &, std::size_t) {
							 if (messages > 1)
								 asyncRead(self, messages - 1);
						 });
	}
	
	static std::atomic<std::size_t> s_runningConnections;
	asio::ssl::stream<asio::ip::tcp::socket> m_socket;
	std::vector<char> m_buffer;
};

std::atomic<std::size_t> ServerConnection::s_runningConnections{0};

class Server {
public:
	Server(IoServices &ioServices, std::size_t connections,
		   std::size_t messages, std::size_t messageSize)
	: m_ioServices{ioServices}
	, m_messages{messages}
	, m_messageSize{messageSize}
	{
		m_context.use_certificate_chain_file((ci::getHomeDirectory()/"domain.com.ssl"/"domain.key.crt").string());
		m_context.use_private_key_file((ci::getHomeDirectory()/"domain.com.ssl"/"domain.com.key").string(), asio::ssl::context::pem);
		asyncAccept(connections);
	}
	
private:
	void asyncAccept(std::size_t connections)
	{
		auto conn = std::make_shared<ServerConnection>( m_ioServices.get(), m_context, m_messageSize );
		
		m_acceptor.async_accept(conn->socket(), [=](const asio::error_code &) {
			conn->start(conn, m_messages);
			if (connections > 1)
				asyncAccept(connections - 1);
		});
	}
	
	IoServices &m_ioServices;
	std::size_t m_messages;
	std::size_t m_messageSize;
	
	asio::ssl::context m_context{asio::ssl::context::tlsv12_server};
	asio::ip::tcp::acceptor m_acceptor{
		m_ioServices.get(), {asio::ip::tcp::v4(), 5555}};
};

class ClientConnection {
public:
	ClientConnection(asio::io_service &ioService,
					 asio::ip::tcp::resolver::iterator iterator, std::size_t messageSize)
	: m_socket{ioService, m_context}
	, m_buffer(messageSize)
	{
		asio::connect(m_socket.lowest_layer(), iterator);
		m_socket.handshake(asio::ssl::stream_base::client);
	}
	
	void asyncSend(std::size_t messages)
	{
		asio::async_write(m_socket, asio::buffer(m_buffer),
						  [=](const asio::error_code &, std::size_t) {
							  if (messages > 1)
								  asyncSend(messages - 1);
						  });
	}
	
private:
	asio::ssl::context m_context{asio::ssl::context::tlsv12_client};
	asio::ssl::stream<asio::ip::tcp::socket> m_socket;
	std::vector<char> m_buffer;
};

std::vector<std::shared_ptr<ClientConnection>> createClients(
IoServices &ioServices, std::size_t messageSize, std::size_t number)
{
	asio::ip::tcp::resolver resolver{ioServices.get()};
	auto iterator = resolver.resolve({"127.0.0.1", "5555"});
	
	std::vector<std::shared_ptr<ClientConnection>> clients;
	std::generate_n(std::back_inserter(clients), number, [&] {
		return std::make_shared<ClientConnection>( ioServices.get(), iterator, messageSize );
	});
	
	return clients;
}

std::chrono::milliseconds measureTransferTime(
std::vector<std::shared_ptr<ClientConnection>> &clients,
std::size_t messages)
{
	auto startTime = std::chrono::steady_clock::now();
	
	for (auto &client : clients)
		client->asyncSend(messages);
	
	while (ServerConnection::runningConnections() != 0)
		std::this_thread::sleep_for(std::chrono::milliseconds{10});
	
	auto stopTime = std::chrono::steady_clock::now();
	
	return std::chrono::duration_cast<std::chrono::milliseconds>( stopTime - startTime);
}

using namespace ci;
using namespace ci::app;
using namespace std;

class SSL_TestApp : public App {
  public:
	void setup() override;
	void mouseDown( MouseEvent event ) override;
	void update() override;
	void draw() override;
};

void SSL_TestApp::setup()
{
	std::size_t threadsNo = 8;
	std::size_t connections = 25;
	std::size_t messages = 10;
	std::size_t messageSize = 10000000;
	
	IoServices ioServices(threadsNo);
	Server server{ioServices, connections, messages, messageSize};
	auto clients = createClients(ioServices, messageSize, connections);
	
	auto duration = measureTransferTime(clients, messages);
	auto seconds = static_cast<double>(duration.count()) / 1000;
	auto megabytes = static_cast<double>(connections * messages * messageSize) / 1024 / 1024;
	
	std::cout << megabytes << " megabytes sent and received in " << seconds
	<< " seconds. (" << (megabytes / seconds) << " MB/s)"
	<< std::endl;
	
	ioServices.stop();
}

void SSL_TestApp::mouseDown( MouseEvent event )
{
}

void SSL_TestApp::update()
{
}

void SSL_TestApp::draw()
{
	gl::clear( Color( 0, 0, 0 ) );
}

CINDER_APP( SSL_TestApp, RendererGl )
