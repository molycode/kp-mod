# navlib is vendored source with no build files of its own, so its target is defined here rather
# than inside navlib/, which is a git subtree of the upstream project and is left untouched.
file(GLOB KP_NAVLIB_FILES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/navlib/*.c")

# An OBJECT library rather than a static one: a static library lets the linker drop members nothing
# references, which would silently change what ships.
add_library(KpNavLib OBJECT ${KP_NAVLIB_FILES})
set_target_properties(KpNavLib PROPERTIES POSITION_INDEPENDENT_CODE ON)
target_include_directories(KpNavLib PRIVATE ${CMAKE_SOURCE_DIR}/src)
KpApplyCompileFlags(KpNavLib)
KpSuppressExternalWarnings(KpNavLib)

# These sources include the SDK headers, which define globals without extern.
if(NOT MSVC)
	target_compile_options(KpNavLib PRIVATE -fcommon)
endif()
