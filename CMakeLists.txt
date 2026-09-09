# The Kingpin: Life of Crime game library, built from Xatrix's released SDK.
cmake_minimum_required(VERSION 4.3.2)

project(KpMod VERSION 1.0.0 LANGUAGES C)

if(PROJECT_IS_TOP_LEVEL)
	set(CMAKE_C_STANDARD 11)
	set(CMAKE_C_STANDARD_REQUIRED ON)
	set(CMAKE_CONFIGURATION_TYPES Debug Release)
endif()

if(NOT COMMAND KpApplyCompileFlags)
	include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/kp_targets.cmake)
endif()

if(NOT TARGET KpCompileFlags)
	include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/compile_flags.cmake)
endif()

add_subdirectory(src)
