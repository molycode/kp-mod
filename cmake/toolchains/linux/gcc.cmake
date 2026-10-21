set(CMAKE_SYSTEM_NAME Linux)

set(KP_ARCH "i386" CACHE STRING "Target architecture: i386 or x86_64")
set_property(CACHE KP_ARCH PROPERTY STRINGS i386 x86_64)

# Cache variable first, environment as a fallback: a preset's `environment` block never reaches an IDE's
# configure step, so an env-only setting is silently lost there.
if(NOT KP_GCC_PATH AND DEFINED ENV{KP_GCC_PATH})
	set(KP_GCC_PATH "$ENV{KP_GCC_PATH}" CACHE PATH "GCC installation root")
endif()

# try_compile re-runs this file in a scratch project that inherits the environment but NOT the cache, so the
# compiler-ABI probe would otherwise fall back to the system GCC and measure the wrong toolchain.
list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES KP_GCC_PATH KP_ARCH)

if(NOT DEFINED CMAKE_C_COMPILER)
	if(KP_GCC_PATH)
		set(CMAKE_C_COMPILER "${KP_GCC_PATH}/bin/gcc")
	else()
		set(CMAKE_C_COMPILER "gcc")
	endif()
endif()

# The project is C-only, but an IDE's preset probe generates a project that enables CXX by default,
# so the toolchain has to describe a working C++ compiler too or that probe fails and the presets
# never appear.
if(NOT DEFINED CMAKE_CXX_COMPILER)
	if(KP_GCC_PATH)
		set(CMAKE_CXX_COMPILER "${KP_GCC_PATH}/bin/g++")
	else()
		set(CMAKE_CXX_COMPILER "g++")
	endif()
endif()

# An engine loads only a library of its own width: i386 for the retail engine, x86_64 for a 64-bit one.
if(KP_ARCH STREQUAL "i386")
	set(CMAKE_SYSTEM_PROCESSOR i386)
	# -mstackrealign: the 1999 engine calls in on a 4-byte-aligned stack, but the compiler assumes
	# the modern 16-byte ABI, so an aligned SSE spill (movapd) faults. Costs a prologue, not optional.
	set(_kp_cflags "-m32 -mstackrealign")
	set(_kp_mflag "-m32")
elseif(KP_ARCH STREQUAL "x86_64")
	set(CMAKE_SYSTEM_PROCESSOR x86_64)
	set(_kp_cflags "-m64")
	set(_kp_mflag "-m64")
else()
	message(FATAL_ERROR "KP_ARCH is '${KP_ARCH}'; expected i386 or x86_64")
endif()

set(CMAKE_C_FLAGS_INIT "${_kp_cflags}")
# The linker flags below are language-agnostic, so C++ must match the C target or it produces objects
# of the other width against the link.
set(CMAKE_CXX_FLAGS_INIT "${_kp_cflags}")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "${_kp_mflag}")
set(CMAKE_EXE_LINKER_FLAGS_INIT "${_kp_mflag}")

if(KP_GCC_PATH)
	message(STATUS "Using GCC from KP_GCC_PATH: ${KP_GCC_PATH}")
else()
	message(STATUS "Using system GCC (set KP_GCC_PATH to use custom GCC)")
endif()

message(STATUS "Target architecture: ${KP_ARCH}")
message(STATUS "CMAKE_C_COMPILER = ${CMAKE_C_COMPILER}")
message(STATUS "CMAKE_CXX_COMPILER = ${CMAKE_CXX_COMPILER}")
