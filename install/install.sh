#!/bin/bash

# Much of the osx and ios build path based on https://gist.github.com/foozmeat/5154962
lower_case=$(echo "$1" | tr '[:upper:]' '[:lower:]')
 
if [ -z $1 ]; then 
	echo Need to provide platform. Possible platforms are linux, macosx, ios. Exiting!
	exit 
fi

#########################
## create prefix dirs
#########################

OPENSSL_BASE_DIR=`pwd`/..

PREFIX_BASE_DIR=${OPENSSL_BASE_DIR}/install/tmp

PREFIX_OPENSSL=${PREFIX_BASE_DIR}/openssl_install
rm -rf ${PREFIX_OPENSSL}
mkdir -p ${PREFIX_OPENSSL}

#########################
## create final path
#########################

FINAL_PATH=`pwd`/..
LIB_DIR=lib
INCLUDE_DIR=include

FINAL_LIB_PATH=${FINAL_PATH}/${LIB_DIR}/${lower_case}
rm -rf ${FINAL_LIB_PATH}
mkdir -p ${FINAL_LIB_PATH}
 
FINAL_INCLUDE_PATH=${FINAL_PATH}/${INCLUDE_DIR}/${lower_case}
rm -rf ${FINAL_INCLUDE_PATH}
mkdir -p ${FINAL_INCLUDE_PATH}

#########################
## different archs
#########################

buildOpenSSL()
{
	cd ${FINAL_PATH}/openssl

	PREFIX=${PREFIX_OPENSSL}
	target=$1

	./Configure ${target} --prefix=${PREFIX}

	if [ ${lower_case} = "ios" ]; then
		sed -id "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -miphoneos-version-min=${SDK_VERSION} !" "Makefile"
	fi 

	make -j 8
	make install_sw
	make clean

	if [ -f "${OPENSSL_BASE_DIR}/openssl/Makefiled" ] ; then 
    rm "${OPENSSL_BASE_DIR}/openssl/Makefiled" 
  fi

	cp -r ${PREFIX}/include/* ${FINAL_INCLUDE_PATH}
	cp ${PREFIX}/lib/*.a ${FINAL_LIB_PATH}
}

buildKey()
{
	# key generation code found here...http://stackoverflow.com/questions/6452756/exception-running-boost-asio-ssl-example
	
	test_key_path=${OPENSSL_BASE_DIR}/test/SSL/assets/dummy_key
	temp_bin_path=${PREFIX_OPENSSL}/bin
	cnf_path=${OPENSSL_BASE_DIR}/openssl/apps/openssl.cnf

	rm -rf ${test_key_path}
	mkdir -p ${test_key_path}
	echo "Generating dummy key"
	${temp_bin_path}/openssl genrsa -out ${test_key_path}/dummy.com.key 2048
	echo "Generating dummy certificate"
	${temp_bin_path}/openssl req -new -sha256 -key ${test_key_path}/dummy.com.key -out ${test_key_path}/dummy.com.csr -config ${cnf_path} <<EOF
us
cinder
cinder
cinder
cinder
cinder
cinder@cinder.com
cinder
cinder
EOF
	echo "Signing certificate"
	${temp_bin_path}/openssl x509 -req -days 3650 -in ${test_key_path}/dummy.com.csr -signkey ${test_key_path}/dummy.com.key -out ${test_key_path}/dummy.com.crt 
	cp ${test_key_path}/dummy.com.key ${test_key_path}/dummy.com.key.secure
	${temp_bin_path}/openssl rsa -in ${test_key_path}/dummy.com.key.secure -out ${test_key_path}/dummy.com.key -config ${cnf_path}
	${temp_bin_path}/openssl dhparam -out ${test_key_path}/dh1024.pem 1024
}

if [ "${lower_case}" = "mac" ] || [ "${lower_case}" = "macosx" ];
then
	
	buildOpenSSL "darwin64-x86_64-cc"
	buildKey

elif [ "${lower_case}" = "linux" ];
then
	
	buildOpenSSL "linux-x86_64"
	buildKey

elif [ "${lower_case}" = "ios" ];
then
	
	export SDK_VERSION="9.3"

	developer=`xcode-select -print-path`
	platform="iPhoneOS"

	export $platform
	export CROSS_TOP="${developer}/Platforms/${platform}.platform/Developer"
	export CROSS_SDK="${platform}${SDK_VERSION}.sdk"
	export BUILD_TOOLS="${developer}"
	export CC="${BUILD_TOOLS}/usr/bin/gcc -arch arm64"

	buildOpenSSL "iphoneos-cross"

else
	echo "Unkown selection: ${1}"
	echo "usage: ./install.sh [platform]"
	echo "accepted platforms are macosx, linux, ios"
	exit 1
fi

echo "Build Complete!"

