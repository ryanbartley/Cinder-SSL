@echo off
setlocal enableextensions

set me=%~n0
set parent=%~dp0
set tmp=%parent%tmp

:: set /p is_32=Enter "32" for 32 bit, "64" for 64 bit version:
set lib_version=lib64
set include_version=include64
:: if %is_32%==32  (
::     set lib_version=lib
::     set include_version=include
::     echo %me%: Copying 32 bit version
:: ) else (
::     echo %me%: Copying 64 bit version
:: )

:: set /p is_lib=Enter "lib" for lib, "bin" for bin version:
:: if %is_lib%==bin (
::     set lib_version=bin64
::     if %is_32%==32 (
::         set lib_version=bin
::     )
::     echo %me%: Copying bin version
:: ) else (
::     echo %me%: Copying lib version
:: )

echo %me%: Parent directory: "%parent%"
echo %me%: Temp directory: "%tmp%"

echo about to delete "%tmp%"
if exist "%tmp%" (
    rmdir "%tmp%" /q /s
    echo "tmp did exist and now it's deleted"
)
mkdir "%tmp%"

echo made tmp

set ssl_final_lib_path="%parent%..\lib\msw"
:: if %is_lib%==bin (
::     set ssl_final_lib_path="%parent%..\bin\msw"    
:: )
echo set up lib path %ssl_final_lib_path%

if exist %ssl_final_lib_path% rmdir %ssl_final_lib_path% /q /s
mkdir %ssl_final_lib_path%\Release
mkdir %ssl_final_lib_path%\Debug
echo Final lib path: %ssl_final_lib_path%

set ssl_final_include_path="%parent%..\include\msw"
if exist %ssl_final_include_path% rmdir %ssl_final_include_path% /q /s
mkdir %ssl_final_include_path%
echo Final include path: %ssl_final_include_path%

set version_name=openssl-1.0.2j-vs2015
echo "%me%: Downloading %version_name% ..."
set compressed="%tmp%\%version_name%.7z"
start /wait bitsadmin /transfer OpenSSLDownload /download /priority normal http://www.npcglib.org/~stathis/downloads/%version_name%.7z %compressed%

echo "%me%: Decompressing ..."
set PATH=%PATH%;C:\Program Files\7-Zip\
7z x %compressed% -o"%tmp%"

echo "%me%: Copying ..."
cd "%tmp%\%version_name%\%lib_version%\"

:: STATIC LIBS
for %%I in (ssleay32MT.lib libeay32MT.lib appMT.pdb libMT.pdb) do xcopy /F %%I %ssl_final_lib_path%
::for %%I in (ssleay32MTd.lib libeay32MTd.lib appMTd.pdb libMTd.pdb) do xcopy /F %%I %ssl_final_lib_path%\Debug\

:: DYNAMIC LIBS
::for %%I in (ssleay32MD.lib ssleay32MD.exp libeay32MD.lib libeay32MD.exp appMD.pdb libMD.pdb) do xcopy /F %%I "%ssl_final_lib_path%\Release\"
::for %%I in (ssleay32MDd.lib ssleay32MDd.exp libeay32MDd.lib libeay32MDd.exp appMDd.pdb libMDd.pdb) do xcopy /F %%I "%ssl_final_lib_path%\Debug\"

xcopy /s /e "%tmp%\%version_name%\%include_version%" %ssl_final_include_path%

echo "%me%: Cleanup..."
cd %parent%
rmdir "%tmp%" /q /s
echo "%me%: DONE."

::PAUSE