#Info

Small shim over [BoringSSL](https://boringssl.googlesource.com/boringssl), Googles ssl implementation. Very similar to OpenSSL. Decision to use this based on [this](https://konradzemek.com/2015/08/16/asio-ssl-and-scalability/) post on performance of asio, openssl, and others.

##How to build boringssl

git submodule init
git submodule update

add boringssl/include to header_search_paths

build boring ssl (inside boringssl root)
	mkdir build
	cd build
	cmake -DCMAKE_BUILD_SYSTEM=Release .. (or debug, also, on mac it weirdly defaults to 32 bit build, look at the CmakeLists.txt to change that)
	make

add proper links to other linker flags for libssl, libcrypto, and libdecrepit

also, you may have to change part of asio. here's the diff -> https://gist.github.com/kzemek/37aa2a2138b2651f2c55

##Generating csr, key, pem

https://support.rackspace.com/how-to/generate-a-csr-with-openssl/

brew install openssl

mkdir ~/domain.com.ssl/
cd ~/domain.com.ssl/

- key gen
openssl genrsa -out ~/domain.com.ssl/domain.com.key 2048

- certificate (examples of how to fill out this info in the above website)
openssl req -new -x509 -days 1826 -key ca.key -out ca.crt

## Sample included

The sample included is a sample that is benchmarking the use of boringssl with asio. I found it [here](https://gist.github.com/kzemek/166e2af5f799d4f833a3). It simply shows how many connections and the speed with which stuff can transfer on local host, testing simply the certification and the underbelly of ssl and asio, without network interference.
