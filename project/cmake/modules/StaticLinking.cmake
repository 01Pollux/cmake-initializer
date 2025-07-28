# ==============================================================================
# Static Linking Module
# ==============================================================================
# This module provides functions to enable static linking of runtime libraries
# with automatic compiler detection for better portability across different systems.
# 
# Supports MSVC, GCC, Clang, Intel, and Emscripten compilers with appropriate
# static linking flags for each platform.

include_guard(GLOBAL)
include(GetCurrentCompiler)

# Enable static runtime linking for a specific target with auto-detection
#
# Usage:
# target_enable_static_linking(
#   TARGET_NAME
#   [PRIVATE|PUBLIC|INTERFACE]
# )
function(target_enable_static_linking TARGET_NAME SCOPE_NAME)
    if(NOT TARGET_NAME OR NOT TARGET ${TARGET_NAME})
        message(FATAL_ERROR "target_enable_static_linking: TARGET argument is required")
    endif()

    if(NOT SCOPE_NAME)
        set(SCOPE_NAME PRIVATE)
    elseif(NOT ${SCOPE_NAME} IN_LIST CMAKE_TARGET_SCOPE_TYPES)
        message(FATAL_ERROR "target_enable_static_linking: Invalid scope '${SCOPE_NAME}' specified. Must be one of: ${CMAKE_TARGET_SCOPE_TYPES}.")
    endif()
    
    # Get current compiler
    get_current_compiler(CURRENT_COMPILER)
    
    # Apply compiler-specific static linking
    if(CURRENT_COMPILER STREQUAL "GCC" OR CURRENT_COMPILER STREQUAL "CLANG")
        target_link_options(${TARGET_NAME} ${SCOPE_NAME} "-static-libstdc++" "-static-libgcc")
        message(STATUS "Enabling static runtime linking for ${CURRENT_COMPILER} target: ${TARGET_NAME}")
    elseif(CURRENT_COMPILER STREQUAL "MSVC")
        set_target_properties(${TARGET_NAME} PROPERTIES
            MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>"
        )
        message(STATUS "Enabling static runtime linking for MSVC target: ${TARGET_NAME}")
    elseif(CURRENT_COMPILER STREQUAL "INTEL")
        target_link_options(${TARGET_NAME} ${SCOPE_NAME} "-static-intel")
        message(STATUS "Enabling static runtime linking for Intel target: ${TARGET_NAME}")
    elseif(CURRENT_COMPILER STREQUAL "EMSCRIPTEN")
        # Emscripten static linking: link C++ standard library statically
        target_link_options(${TARGET_NAME} ${SCOPE_NAME} "-static-libstdc++")
        # For more portable/standalone WebAssembly output
        target_link_options(${TARGET_NAME} ${SCOPE_NAME} "SHELL:-s STANDALONE_WASM=1")
        target_link_options(${TARGET_NAME} ${SCOPE_NAME} "SHELL:-s WASM=1")
        message(STATUS "Enabling static runtime linking for Emscripten target: ${TARGET_NAME}")
    else()
        message(WARNING "Static runtime linking not supported for compiler: ${CURRENT_COMPILER}")
    endif()
endfunction()
