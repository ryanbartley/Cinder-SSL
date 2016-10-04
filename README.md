#Info

Small shim over [OpenSSL](https://github.com/openssl/openssl). Mostly concerned with a simple way of including OpenSSL in Cinder projects.

##INSTALLATION

* After cloning the repo, run `git submodule update --init`. This will retreive the correct openssl version.
* On Windows, execute the installation script using `cd install && install.bat`.
* On Linux, iOS, MacOSX, execute the installation script using `cd install && ./install.sh [platform]`. Values for platform are linux, ios, macosx
* On all platforms except iOS, at the end of the install it will ask you to answer some questions to build a dummy certificate for the test. You don't need to give valid answers (I just put "cinder" in over and over). It's just for local test purposes and is ignored by git.

After installation all libraries and includes should be where the need to be.

## Test included

The test included that benchmarks the use of OpenSSL with asio. I found it [here](https://gist.github.com/kzemek/166e2af5f799d4f833a3). It simply shows how many connections and the speed with which stuff can transfer on local host, testing simply the certification and the underbelly of ssl and asio, without network interference.
