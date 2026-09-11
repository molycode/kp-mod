set(KP_TARGET_NAME "KpGame")

file(GLOB KP_HEADER_FILES CONFIGURE_DEPENDS "*.h")
file(GLOB KP_SOURCE_FILES CONFIGURE_DEPENDS "*.c")

source_group("Header" FILES ${KP_HEADER_FILES})
source_group("Source" FILES ${KP_SOURCE_FILES})

if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
	add_library(${KP_TARGET_NAME} SHARED ${KP_HEADER_FILES} ${KP_SOURCE_FILES})
	set_property(DIRECTORY ${CMAKE_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT ${KP_TARGET_NAME})
	set_target_properties(${KP_TARGET_NAME} PROPERTIES OUTPUT_NAME "gamex86")
	target_link_libraries(${KP_TARGET_NAME} PRIVATE KpNavLib "winmm.lib")
	target_link_options(${KP_TARGET_NAME} PRIVATE "/DEF:${CMAKE_CURRENT_SOURCE_DIR}/game.def")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
	add_library(${KP_TARGET_NAME} SHARED ${KP_HEADER_FILES} ${KP_SOURCE_FILES})
	set_target_properties(${KP_TARGET_NAME} PROPERTIES OUTPUT_NAME "gamei386" PREFIX "")
	target_include_directories(${KP_TARGET_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
	target_link_libraries(${KP_TARGET_NAME} PRIVATE KpNavLib m)
	# game.map is the Linux counterpart of game.def: the engine dlsym()s GetGameAPI and nothing else.
	target_link_options(${KP_TARGET_NAME} PRIVATE "-Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/game.map")
	# Savegames are stamped with the build id, so it must be present even if the linker defaults it off.
	target_link_options(${KP_TARGET_NAME} PRIVATE "-Wl,--build-id=sha1")

	# Only GCC produces a ship/ artifact: a Clang build is a diagnostic second opinion, never the
	# released library. The stripped copy keeps the built one's build id, so a crash in the shipped
	# library symbolises against the symbols left beside it.
	if(CMAKE_BUILD_TYPE STREQUAL "Release" AND CMAKE_C_COMPILER_ID STREQUAL "GNU")
		set(KP_SHIP_DIR "$<TARGET_FILE_DIR:${KP_TARGET_NAME}>/ship")
		add_custom_command(TARGET ${KP_TARGET_NAME} POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E make_directory "${KP_SHIP_DIR}"
			COMMAND ${CMAKE_COMMAND} -E copy "$<TARGET_FILE:${KP_TARGET_NAME}>" "${KP_SHIP_DIR}/$<TARGET_FILE_NAME:${KP_TARGET_NAME}>"
			COMMAND ${CMAKE_STRIP} --strip-all "${KP_SHIP_DIR}/$<TARGET_FILE_NAME:${KP_TARGET_NAME}>"
			COMMENT "Stripping the shipping library into ship/"
			VERBATIM)
	endif()
else()
	message(FATAL_ERROR "Unsupported platform '${CMAKE_SYSTEM_NAME}'. Add it to src/CMakeLists.txt.")
endif()

KpApplyCompileFlags(${KP_TARGET_NAME})

# The SDK headers define globals without extern; GCC 10 flipped this default.
if(NOT MSVC)
	target_compile_options(${KP_TARGET_NAME} PRIVATE -fcommon)
endif()
