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
	ios_sdk_version="8.2"
else
	echo "Unkown selection: ${1}"
	echo "usage: ./install.sh [platform]"
	echo "accepted platforms are macosx, linux, ios"
	exit 1
fi

build()
{
	config=$1
	config_path=$2
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
	
	./Configure ${target} --${config} --prefix=${temp_library_path}
	
	make -j 6
	make install_sw
	make clean
	
	cp -r ${temp_library_path}/include/ ${final_include_path}
	cp ${temp_library_path}/lib/*.a ${final_library_path}

	rm -rf ${block_absolute_path}/tmp
	
	cd ..
}

buildIos()
{
	developer=`xcode-select -print-path`
	platform="iPhoneOS"
	config=$1
	config_paht=$2
	
	export $platform
	export CROSS_TOP="${developer}/Platforms/${platform}.platform/Developer"
	export CROSS_SDK="${platform}${ios_sdk_version}.sdk"
	export BUILD_TOOLS="${developer}"
	export CC="${BUILD_TOOLS}/usr/bin/gcc -arch arm64"

	echo "Building openssl for ${platform} ${ios_sdk_version} arm64"

	./Configure ${target} --${config} --openssldir="/tmp/${lib_path}${config_path}"

	sed -id "s!^CFLAG=!CFLAG=isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -miphoneos-version-min=${SDK_VERSION} !" "Makefile"

	make
	make install
	make clean
}

for i in 0 1 
do
	build ${config_settings[i]} ${config_paths[i]}
done




