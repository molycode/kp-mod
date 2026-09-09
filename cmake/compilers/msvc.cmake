add_library(KpCompileFlags INTERFACE)
target_compile_options(KpCompileFlags INTERFACE
	/W4
	/WX
	/wd4100
	/permissive-
)

message(STATUS "MSVC ${CMAKE_C_COMPILER_VERSION} compiler flags configured")
