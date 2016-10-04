#Info

Small shim over [OpenSSL](https://github.com/openssl/openssl). Mostly concerned with a simple way of including OpenSSL in Cinder projects.

##INSTALLATION

* After cloning the repo, run `git submodule update --init`. This will retreive the correct openssl version.
* On Windows, execute the installation script using `cd install && install.bat`.
* On Linux, iOS, MacOSX, execute the installation script using `cd install && ./install.sh [platform]`. Values for platform are linux, ios, macosx

After installation all libraries and includes should be where the need to be.

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
