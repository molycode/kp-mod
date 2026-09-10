set(KP_TARGET_NAME "KpGame")

file(GLOB KP_HEADER_FILES CONFIGURE_DEPENDS "*.h")
file(GLOB KP_SOURCE_FILES CONFIGURE_DEPENDS "*.c")
file(GLOB KP_NAVLIB_FILES CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/external/navlib/*.c")

source_group("Header" FILES ${KP_HEADER_FILES})
source_group("Source" FILES ${KP_SOURCE_FILES})

if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
	add_library(${KP_TARGET_NAME} SHARED ${KP_HEADER_FILES} ${KP_SOURCE_FILES})
	set_property(DIRECTORY ${CMAKE_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT ${KP_TARGET_NAME})
	set_target_properties(${KP_TARGET_NAME} PROPERTIES OUTPUT_NAME "gamex86")
	target_link_libraries(${KP_TARGET_NAME} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/navlib/navlib.lib" "winmm.lib")
	target_link_options(${KP_TARGET_NAME} PRIVATE "/NODEFAULTLIB:libc.lib" "/DEF:${CMAKE_CURRENT_SOURCE_DIR}/game.def")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
	# navlib.lib is MSVC-only, so Linux builds the reconstruction in external/ instead.
	source_group("NavLib" FILES ${KP_NAVLIB_FILES})
	add_library(${KP_TARGET_NAME} SHARED ${KP_HEADER_FILES} ${KP_SOURCE_FILES} ${KP_NAVLIB_FILES})
	KpSuppressExternalWarnings(${KP_NAVLIB_FILES})
	set_target_properties(${KP_TARGET_NAME} PROPERTIES OUTPUT_NAME "gamei386" PREFIX "")
	target_include_directories(${KP_TARGET_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
	target_link_libraries(${KP_TARGET_NAME} PRIVATE m)
	# game.map is the Linux counterpart of game.def: the engine dlsym()s GetGameAPI and nothing else.
	target_link_options(${KP_TARGET_NAME} PRIVATE "-Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/game.map")
	# Savegames are stamped with the build id, so it must be present even if the linker defaults it off.
	target_link_options(${KP_TARGET_NAME} PRIVATE "-Wl,--build-id=sha1")
else()
	message(FATAL_ERROR "Unsupported platform '${CMAKE_SYSTEM_NAME}'. Add it to src/CMakeLists.txt.")
endif()

KpApplyCompileFlags(${KP_TARGET_NAME})

# The SDK headers define globals without extern; GCC 10 flipped this default.
if(NOT MSVC)
	target_compile_options(${KP_TARGET_NAME} PRIVATE -fcommon)
endif()
