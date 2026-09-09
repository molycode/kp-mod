set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR i386)

# Both paths accept a cache variable and fall back to the environment. An environment-only setting is
# unreachable from an IDE: QtCreator applies a preset's `environment` block to the BUILD step, never to
# the configure, so the toolchain would never see it.
if(NOT KP_CLANG_PATH AND DEFINED ENV{KP_CLANG_PATH})
	set(KP_CLANG_PATH "$ENV{KP_CLANG_PATH}" CACHE PATH "Clang installation root")
endif()

if(NOT KP_GCC_PATH AND DEFINED ENV{KP_GCC_PATH})
	set(KP_GCC_PATH "$ENV{KP_GCC_PATH}" CACHE PATH "GCC installation supplying the 32-bit runtime to Clang builds")
endif()

# try_compile re-runs this file in a scratch project that inherits the environment but NOT the cache, so
# without this the compiler-ABI probe would measure a different toolchain than the build then uses.
list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES KP_CLANG_PATH KP_GCC_PATH)

if(KP_CLANG_PATH)
	set(CMAKE_C_COMPILER "${KP_CLANG_PATH}/bin/clang" CACHE FILEPATH "" FORCE)
elseif(NOT DEFINED CMAKE_C_COMPILER)
	set(CMAKE_C_COMPILER "clang")
endif()

# The retail engine that dlopens this library is i386; a 64-bit build cannot be loaded.
set(CMAKE_C_FLAGS_INIT "-m32")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "-m32")
set(CMAKE_EXE_LINKER_FLAGS_INIT "-m32")

if(KP_GCC_PATH)
	file(GLOB _gcc_ver_dirs LIST_DIRECTORIES true "${KP_GCC_PATH}/lib/gcc/x86_64-pc-linux-gnu/*")
	list(SORT _gcc_ver_dirs COMPARE NATURAL ORDER DESCENDING)
	list(GET _gcc_ver_dirs 0 _gcc_install_dir)
	add_compile_options(--gcc-install-dir=${_gcc_install_dir})
	add_link_options(--gcc-install-dir=${_gcc_install_dir})
	message(STATUS "Using GCC runtime from KP_GCC_PATH: ${KP_GCC_PATH}")
else()
	message(STATUS "Using the system GCC runtime (set KP_GCC_PATH to pin one)")
endif()

if(KP_CLANG_PATH)
	message(STATUS "Using Clang from KP_CLANG_PATH: ${KP_CLANG_PATH}")
else()
	message(STATUS "Using system Clang (set KP_CLANG_PATH to use custom Clang)")
endif()

message(STATUS "CMAKE_C_COMPILER = ${CMAKE_C_COMPILER}")
