# Read as a property, not linked: a PRIVATE link on a library still lands in INTERFACE_LINK_LIBRARIES
# as $<LINK_ONLY:KpCompileFlags>, dragging a build-only target into anything that later consumes this one.
function(KpApplyCompileFlags name)
	target_compile_options(${name} PRIVATE $<TARGET_PROPERTY:KpCompileFlags,INTERFACE_COMPILE_OPTIONS>)
endfunction()

# External sources compiled into a Kingpin target. They are loose .c files rather than their own
# build, so the suppression is per source file instead of per target.
function(KpSuppressExternalWarnings target_name)
	if(NOT TARGET ${target_name})
		message(FATAL_ERROR "KpSuppressExternalWarnings: '${target_name}' is not a target")
	endif()

	if(MSVC)
		target_compile_options(${target_name} PRIVATE /w)
	else()
		target_compile_options(${target_name} PRIVATE -w)
	endif()
endfunction()
