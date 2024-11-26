set(KP_PROJECT_NAME "game")
message(STATUS "KP_PROJECT_NAME = ${KP_PROJECT_NAME}")
set(SRC_FOLDER "${CMAKE_SOURCE_DIR}/src")

if (${CMAKE_SYSTEM_NAME} STREQUAL "Windows")
	add_library(${KP_PROJECT_NAME} SHARED)
	set_property(DIRECTORY ${CMAKE_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT ${KP_PROJECT_NAME})
	target_link_libraries(${KP_PROJECT_NAME} PRIVATE "${SRC_FOLDER}/navlib/navlib.lib" "winmm.lib")
	target_link_options(${KP_PROJECT_NAME} PRIVATE "/NODEFAULTLIB:libc.lib" "/DEF:${SRC_FOLDER}/game.def")
	set_target_properties(${KP_PROJECT_NAME} PROPERTIES OUTPUT_NAME "gamex86")
elseif(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
	add_library(${KP_PROJECT_NAME})
	# todo
else()
	message(FATAL_ERROR "Unsupported platform! '${CMAKE_SYSTEM_NAME}'")
endif()

ApplyCommonCompilerAndLinkerFlags(${KP_PROJECT_NAME})

set(HEADER_FILES
	"ai_bitch.h"
	"ai_bitch_tables.h"
	"ai_bum_sit.h"
	"ai_dog.h"
	"ai_dog_tables.h"
	"ai_punk.h"
	"ai_punk_tables.h"
	"ai_runt.h"
	"ai_runt_tables.h"
	"ai_shorty.h"
	"ai_shorty_tables.h"
	"ai_skinny_tables.h"
	"ai_thug.h"
	"ai_thug2.h"
	"ai_thug2_tables.h"
	"ai_thug_tables.h"
	"ai_whore.h"
	"ai_whore_tables.h"
	"ep_all.h"
	"ep_log.h"
	"game.h"
	"g_ai.h"
	"g_func.h"
	"g_local.h"
	"g_nav.h"
	"g_teamplay.h"
	"m_player.h"
	"q_shared.h"
	"vehicles.h"
	"veh_defs.h"
	"voice.h"
	"voice_bitch.h"
	"voice_punk.h"
)

set(SOURCE_FILES
	"ai_bitch.c"
	"ai_bum_sit.c"
	"ai_dog.c"
	"ai_punk.c"
	"ai_runt.c"
	"ai_shorty.c"
	"ai_skinny.c"
	"ai_thug.c"
	"ai_thug_sit.c"
	"ai_whore.c"
	"ep_all.c"
	"ep_crystalpalace.c"
	"ep_log.c"
	"ep_posionville.c"
	"ep_radiocity.c"
	"ep_shipyards.c"
	"ep_skidrow.c"
	"ep_steeltown.c"
	"ep_trainyard.c"
	"g_ai.c"
	"g_ai_ents.c"
	"g_ai_fight.c"
	"g_ai_memory.c"
	"g_cast.c"
	"g_chase.c"
	"g_cmds.c"
	"g_combat.c"
	"g_fog.c"
	"g_func.c"
	"g_items.c"
	"g_joe_misc.c"
	"g_main.c"
	"g_misc.c"
	"g_pawn.c"
	"g_phys.c"
	"g_save.c"
	"g_spawn.c"
	"g_svcmds.c"
	"g_target.c"
	"g_teamplay.c"
	"g_trigger.c"
	"g_utils.c"
	"g_weapon.c"
	"m_bbox.c"
	"m_move.c"
	"p_client.c"
	"p_hud.c"
	"p_trail.c"
	"p_view.c"
	"p_weapon.c"
	"q_shared.c"
	"vehicles.c"
	"voice.c"
	"voice_bitch.c"
	"voice_punk.c"
)

source_group("Header" FILES ${HEADER_FILES})
source_group("Source" FILES ${SOURCE_FILES})

target_sources(
		${KP_PROJECT_NAME}
	PRIVATE
		${HEADER_FILES}
	PRIVATE
		${SOURCE_FILES}
)

function(ApplyMolySpecifics target)
	set_property(TARGET ${target} 
		APPEND PROPERTY 
		VS_DEBUGGER_COMMAND "<path-to>/kpded2.exe")

	set_property(TARGET ${target} 
		APPEND PROPERTY 
		VS_DEBUGGER_COMMAND_ARGUMENTS "<arguments to pass>")
	
	set_property(TARGET ${target} 
		APPEND PROPERTY 
		VS_DEBUGGER_WORKING_DIRECTORY "<path-to-directory>")
	
	set(COPY_DEST_FOLDER "<path-to-destination>")
	
	add_custom_command(TARGET ${KP_PROJECT_NAME} POST_BUILD
		COMMAND if exist "$<TARGET_FILE:${KP_PROJECT_NAME}>"
			${CMAKE_COMMAND} -E copy_if_different
			"$<TARGET_FILE:${KP_PROJECT_NAME}>"
			"${COPY_DEST_FOLDER}"
		COMMAND if exist "$<TARGET_PDB_FILE:${KP_PROJECT_NAME}>"
			${CMAKE_COMMAND} -E copy_if_different
			"$<TARGET_PDB_FILE:${KP_PROJECT_NAME}>"
			"${COPY_DEST_FOLDER}"
		COMMENT "copying DLL and PDB to ${COPY_DEST_FOLDER}"
	)
endfunction()

#ApplyMolySpecifics(${KP_PROJECT_NAME})