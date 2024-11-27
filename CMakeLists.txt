cmake_minimum_required(VERSION 3.31)

set(CMAKE_CONFIGURATION_TYPES Debug Release)
set(CMAKE_CONFIGURATION_TYPES "${CMAKE_CONFIGURATION_TYPES}" CACHE STRING "Reset the configurations to what we need" FORCE)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED True)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/bin)
project("kp-mod" VERSION 1.0 LANGUAGES C)

if(NOT DEFINED CMAKE_SYSTEM_NAME)
	message(FATAL_ERROR "CMAKE_SYSTEM_NAME not defined! Supply one in the corresponding toolchain file.")
endif()

function(ApplyCommonCompilerAndLinkerFlags target)
	message(STATUS "applying compiler/linker flags to target: ${target}")

	if(${CMAKE_SYSTEM_NAME} STREQUAL "Windows")
		target_compile_definitions(
				${target}
			PRIVATE
				WIN32
				$<$<CONFIG:Debug>:DEBUG _DEBUG>
				_CRT_SECURE_NO_WARNINGS
		)
	elseif(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
		target_compile_definitions(
				${target}
			PRIVATE
				$<$<NOT:$<CONFIG:Debug>>:NDEBUG>
		)
	endif()

	if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
		target_compile_options(
				${target}
			PRIVATE
				/W4
				/MP
				/wd4100
				$<$<CONFIG:Debug>:/ZI /MTd>
				$<$<CONFIG:Release>:/MT /Oi /GL /fp:fast>
		)
		target_link_options(
				${target}
			PRIVATE
				/SUBSYSTEM:WINDOWS
				/SAFESEH:NO
				$<$<CONFIG:Debug>:/MAP /OPT:NOREF /OPT:NOICF>
				$<$<CONFIG:Release>:/OPT:REF /OPT:ICF /LTCG:incremental /MANIFEST:NO>
		)
	elseif(CMAKE_C_COMPILER_ID MATCHES "[Cc]lang")
		set(COMMON_COMPILE_OPTIONS
			-Wall
			-Wextra
			-pedantic
			-Werror
			-ffast-math
			-flax-vector-conversions
			-fvisibility=hidden
			-fPIC
			-fno-exceptions
			-fno-rtti
			-Wno-unused-parameter
			#-v
		)
	
		set(DEBUG_COMPILE_OPTIONS
			-g3
			-O0
		)
	
		set(PROFILE_COMPILE_OPTIONS
			-g
			-O2
		)
	
		set(RELEASE_COMPILE_OPTIONS
			-g0
			-O3
		)

		target_compile_options(
				${target}
			PRIVATE
				"${COMMON_COMPILE_OPTIONS}"
				"$<$<CONFIG:Debug>:${DEBUG_COMPILE_OPTIONS}>"
				"$<$<CONFIG:Release>:${RELEASE_COMPILE_OPTIONS}>"
		)
	elseif(CMAKE_C_COMPILER_ID STREQUAL "GNU")
		set(COMMON_COMPILE_OPTIONS
			-Wall
			-Wextra
			-pedantic
			-Werror
			-ffast-math
			-flax-vector-conversions
			-fvisibility=hidden
			-fPIC
			-fno-exceptions
			-fno-rtti
			-Wno-unused-parameter
			#-v
		)
	
		set(DEBUG_COMPILE_OPTIONS
			-g3
			-O0
		)
	
		set(PROFILE_COMPILE_OPTIONS
			-g
			-O2
		)
	
		set(RELEASE_COMPILE_OPTIONS
			-g0
			-O3
		)

		target_compile_options(
				${target}
			PRIVATE
				"${COMMON_COMPILE_OPTIONS}"
				"$<$<CONFIG:Debug>:${DEBUG_COMPILE_OPTIONS}>"
				"$<$<CONFIG:Release>:${RELEASE_COMPILE_OPTIONS}>"
		)
	else()
		message(FATAL_ERROR "Unsupported compiler! '${CMAKE_C_COMPILER_ID}'")
	endif()
endfunction()

add_subdirectory("src")

message(STATUS "CMAKE_SYSTEM_NAME = ${CMAKE_SYSTEM_NAME}")
message(STATUS "CMAKE_GENERATOR = ${CMAKE_GENERATOR}")
message(STATUS "CMAKE_CONFIGURATION_TYPES = ${CMAKE_CONFIGURATION_TYPES}")
message(STATUS "CMAKE_CURRENT_LIST_DIR = ${CMAKE_CURRENT_LIST_DIR}")
message(STATUS "CMAKE_CURRENT_SOURCE_DIR = ${CMAKE_CURRENT_SOURCE_DIR}")
message(STATUS "CMAKE_C_COMPILER = ${CMAKE_C_COMPILER}")
message(STATUS "CMAKE_C_COMPILER_ID = ${CMAKE_C_COMPILER_ID}")
message(STATUS "PROJECT_SOURCE_DIR = ${PROJECT_SOURCE_DIR}")
message(STATUS "PROJECT_BINARY_DIR = ${PROJECT_BINARY_DIR}")
message(STATUS "CMAKE_C_FLAGS = ${CMAKE_C_FLAGS}")
