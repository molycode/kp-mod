# Selects the compiler flag set for Kingpin-owned code, creating the KpCompileFlags INTERFACE library.
# Its own file so the selection stays in one place, mirroring the tge module layout.

if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
	include(${CMAKE_CURRENT_LIST_DIR}/compilers/msvc.cmake)
elseif(CMAKE_C_COMPILER_ID MATCHES "[Cc]lang")
	include(${CMAKE_CURRENT_LIST_DIR}/compilers/clang.cmake)
elseif(CMAKE_C_COMPILER_ID STREQUAL "GNU")
	include(${CMAKE_CURRENT_LIST_DIR}/compilers/gcc.cmake)
endif()

# One option rather than raw flags in a preset: the toolchain owns CMAKE_C_FLAGS_INIT
# (-m32 -mstackrealign, and -mstackrealign is mandatory here), and a preset that sets CMAKE_C_FLAGS
# replaces it instead of adding to it.
set(KP_SANITIZER "none" CACHE STRING "Sanitizer to build with: none, address or undefined")
set_property(CACHE KP_SANITIZER PROPERTY STRINGS none address undefined)

if(NOT KP_SANITIZER STREQUAL "none")
	if(NOT KP_SANITIZER MATCHES "^(address|undefined)$")
		message(FATAL_ERROR "KP_SANITIZER is '${KP_SANITIZER}'; expected none, address or undefined")
	endif()

	if(MSVC)
		message(FATAL_ERROR "KP_SANITIZER has never been exercised with MSVC; wire it before using it")
	endif()

	target_compile_options(KpCompileFlags INTERFACE -fsanitize=${KP_SANITIZER} -fno-omit-frame-pointer)
	target_link_options(KpCompileFlags INTERFACE -fsanitize=${KP_SANITIZER})
	message(STATUS "Sanitizer enabled: ${KP_SANITIZER}")
endif()
