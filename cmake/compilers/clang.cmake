add_library(KpCompileFlags INTERFACE)
target_compile_options(KpCompileFlags INTERFACE
	-g
	-Wall
	-Wextra
	-Werror
	-Wno-unused-parameter
)

message(STATUS "Clang ${CMAKE_C_COMPILER_VERSION} compiler flags configured")
