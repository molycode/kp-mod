@ECHO OFF

SET solutionfolder="%~dp0solution"
IF NOT EXIST %solutionfolder% mkdir %solutionfolder%

cmake -G "Visual Studio 17 2022" -A Win32 -S %~dp0 -B %solutionfolder% -D CMAKE_TOOLCHAIN_FILE=cmake\toolchains\windows\msvc.cmake
cmake-gui -S %~dp0 -B %solutionfolder%
