@ECHO OFF

SET solutionfolder="%~dp0solution"
IF NOT EXIST %solutionfolder% mkdir %solutionfolder%

%~dp0Tools\CMake\cmake-bins\windows\bin\cmake -G "Visual Studio 17 2022" -A Win32 -S %~dp0 -B %solutionfolder% -D CMAKE_TOOLCHAIN_FILE=Tools\CMake\toolchains\windows-msvc.cmake
%~dp0Tools\CMake\cmake-bins\windows\bin\cmake-gui -S %~dp0 -B %solutionfolder%
