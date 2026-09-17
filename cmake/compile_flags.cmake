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
set(KP_SANITIZER "none" CACHE STRING "Sanitizer to build with: none, address, undefined or address,undefined")
set_property(CACHE KP_SANITIZER PROPERTY STRINGS none address undefined address,undefined)

if(NOT KP_SANITIZER STREQUAL "none")
	if(NOT KP_SANITIZER MATCHES "^(address|undefined|address,undefined)$")
		message(FATAL_ERROR "KP_SANITIZER is '${KP_SANITIZER}'; expected none, address, undefined or address,undefined")
	endif()

	if(MSVC)
		message(FATAL_ERROR "KP_SANITIZER has never been exercised with MSVC; wire it before using it")
	endif()

	target_compile_options(KpCompileFlags INTERFACE -fsanitize=${KP_SANITIZER} -fno-omit-frame-pointer)
	target_link_options(KpCompileFlags INTERFACE -fsanitize=${KP_SANITIZER})

	if(KP_SANITIZER STREQUAL "undefined")
		# The library is dlopen'd on servers without libubsan, where the load fails outright.
		# Not for address: that runtime cannot be static in a shared object, it must come first,
		# which is also why an address build needs LD_PRELOAD of libasan at the server.
		target_link_options(KpCompileFlags INTERFACE -static-libubsan)
	endif()

	if(KP_SANITIZER MATCHES "address")
		# Report and carry on instead of aborting, so one hands-on session can surface more
		# than its first finding. Needs ASAN_OPTIONS=halt_on_error=0 to take effect.
		target_compile_options(KpCompileFlags INTERFACE -fsanitize-recover=address)
		target_link_options(KpCompileFlags INTERFACE -fsanitize-recover=address)
	endif()

	message(STATUS "Sanitizer enabled: ${KP_SANITIZER}")
endif()
