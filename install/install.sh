#!/bin/bash

# Much of the osx and ios build path based on https://gist.github.com/foozmeat/5154962

cd ..

lib_path=""
target=""
ios_sdk_version=""
declare -a config_settings=("debug" "release")
declare -a config_paths=("/Debug" "/Release")

lower_case=$(echo "$1" | tr '[:upper:]' '[:lower:]')
echo $lower_case
if [ "${lower_case}" = "mac" ] || [ "${lower_case}" = "macosx" ];
then
	lib_path="lib/macosx"
	target="darwin64-x86_64-cc"
elif [ "${lower_case}" = "linux" ];
then
	lib_path="lib/linux"
	target="linux-x86_64"
elif [ "${lower_case}" = "ios" ];
then
	lib_path="lib/ios"
	target="iphoneos-cross"
	ios_sdk_version="9.3"
else
	echo "Unkown selection: ${1}"
	echo "usage: ./install.sh [platform]"
	echo "accepted platforms are macosx, linux, ios"
	exit 1
fi

build()
{
	prefix=$1

	if [ "${config}" = "debug" ]; then
		./Configure ${target} --${config} --prefix=${prefix}
	else
		./Configure ${target} --prefix=${prefix}
	fi

	make -j 6
	make install_sw
	make clean
}

buildIos()
{
	developer=`xcode-select -print-path`
	platform="iPhoneOS"
	prefix=$1

	export $platform
	export CROSS_TOP="${developer}/Platforms/${platform}.platform/Developer"
	export CROSS_SDK="${platform}${ios_sdk_version}.sdk"
	export BUILD_TOOLS="${developer}"
	export CC="${BUILD_TOOLS}/usr/bin/gcc -arch arm64"

	echo "Building openssl for ${platform} ${ios_sdk_version} arm64"
	if [ "${config}" = "debug" ]; then
		./Configure ${target} --${config} --prefix=${prefix}
	else
		./Configure ${target} --prefix=${prefix}
	fi

	#sed -id "s!^CFLAG=!CFLAG=isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -miphoneos-version-min=${SDK_VERSION} !" "Makefile"

	make -j 6
	make install_sw
	make clean

	if [ -f Makefiled ] ; then rm Makefile ; fi
}

for i in 0 1 
do
	config=${config_settings[i]}
	config_path=${config_paths[i]}
	# we should be starting in the blocks absolute path
	block_absolute_path=`pwd`
	final_library_path=${block_absolute_path}/${lib_path}${config_path}
	final_include_path=${block_absolute_path}/lib/include
	temp_library_path=${block_absolute_path}/tmp/openssl
	
	echo "Building openssl for ${lower_case}, temp_path: ${temp_library_path}, final_path: ${final_library_path}"
	
	rm -rf ${final_library_path}
	rm -rf ${temp_library_path}
	rm -rf ${final_include_path}
	mkdir -p ${final_library_path}
	mkdir -p ${temp_library_path}
	mkdir -p ${final_include_path}
	
	cd openssl
	
	if [ "${lower_case}" = "ios" ]; then		
		buildIos ${temp_library_path}
	else
		build ${temp_library_path}
	fi

	cd ..

	cp -r ${temp_library_path}/include/ ${final_include_path}
	cp ${temp_library_path}/lib/*.a ${final_library_path}
done

# generate a key so that we can test with the app.
if [ "${lower_case}" != "ios" ]; then
	current_dir=`pwd`
	test_key_path=${current_dir}/test/SSL_Test/assets/dummy_key
	temp_bin_path=${current_dir}/tmp/openssl/bin
	cnf_path=${current_dir}/openssl/apps/openssl.cnf

	rm -rf ${test_key_path}
	mkdir -p ${test_key_path}
	echo "Generating dummy key"
	${temp_bin_path}/openssl genrsa -out ${test_key_path}/dummy.com.key 2048
	echo "Generating dummy certificate"
	${temp_bin_path}/openssl req -new -sha256 -key ${test_key_path}/dummy.com.key -out ${test_key_path}/dummy.com.csr -config ${cnf_path}
	echo "Signing certificate"
	${temp_bin_path}/openssl x509 -req -days 3650 -in ${test_key_path}/dummy.com.csr -signkey ${test_key_path}/dummy.com.key -out ${test_key_path}/dummy.com.crt
	cp ${test_key_path}/dummy.com.key ${test_key_path}/dummy.com.key.secure
	${temp_bin_path}/openssl rsa -in ${test_key_path}/dummy.com.key.secure -out ${test_key_path}/dummy.com.key -config ${cnf_path}
	${temp_bin_path}/openssl dhparam -out ${test_key_path}/dh1024.pem 1024
else
	echo "Need to run osx config to generate key."
fi

rm -rf tmp
echo "Build Complete!"

