add_library(KpCompileFlags INTERFACE)
target_compile_options(KpCompileFlags INTERFACE
	-Wall
	-Wextra
	-Werror
	-Wno-unused-parameter
)

message(STATUS "GCC ${CMAKE_C_COMPILER_VERSION} compiler flags configured")
