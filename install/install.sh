#!/bin/bash

# Much of the osx and ios build path based on https://gist.github.com/foozmeat/5154962

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
	echo "Building openssl for ${lower_case}"
	config=$1
	config_path=$2
	echo ./Configure ${target} --${config} --openssldir="${lib_path}${config_path}"
	#make
	#make install
	#make clean
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

	./Configure ${target} --${config} --openssldir="${lib_path}${config_path}"

	sed -id "s!^CFLAG=!CFLAG=isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -miphoneos-version-min=${SDK_VERSION} !" "Makefile"

	make
	make install
	make clean
}

cd ../openssl

for i in 0 1 
do
	if [ "${lower_case}" != "ios" ]; then
		build ${config_settings[i]} ${config_paths[i]}
	else
		buildIos ${config_settings[i]} ${config_paths[i]}
	fi	
done




