# Selects the compiler flag set for Kingpin-owned code, creating the KpCompileFlags INTERFACE library.
# Its own file so the selection stays in one place, mirroring the tge module layout.

if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
	include(${CMAKE_CURRENT_LIST_DIR}/compilers/msvc.cmake)
elseif(CMAKE_C_COMPILER_ID MATCHES "[Cc]lang")
	include(${CMAKE_CURRENT_LIST_DIR}/compilers/clang.cmake)
elseif(CMAKE_C_COMPILER_ID STREQUAL "GNU")
	include(${CMAKE_CURRENT_LIST_DIR}/compilers/gcc.cmake)
endif()
