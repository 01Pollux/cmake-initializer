# ==============================================================================
# Debug Options Configuration
# ==============================================================================
# This module provides debug-related options and configurations for different
# compilers, including Edit and Continue support for MSVC.

include(CheckCXXCompilerFlag)
include(GetCurrentCompiler)

#
# Configure debug options for a specific target
#
# Usage:
# target_enable_debug_options(
#   TARGET_NAME
#   [PRIVATE|PUBLIC|INTERFACE]
#   [ENABLE_EDIT_AND_CONTINUE]
#   [ENABLE_DEBUG_INFO]
#   [DEBUG_INFO_LEVEL level]  # 0-3 for GCC/Clang, ignored for MSVC
# )
function(target_enable_debug_options TARGET_NAME)
    cmake_parse_arguments(ARG 
        "ENABLE_EDIT_AND_CONTINUE;ENABLE_DEBUG_INFO" 
        "DEBUG_INFO_LEVEL" 
        "" 
        ${ARGN}
    )

    # Handle scope
    set(SCOPE_NAME "PRIVATE")
    if(ARG_UNPARSED_ARGUMENTS)
        list(GET ARG_UNPARSED_ARGUMENTS 0 POTENTIAL_SCOPE)
        if(POTENTIAL_SCOPE IN_LIST CMAKE_TARGET_SCOPE_TYPES)
            set(SCOPE_NAME ${POTENTIAL_SCOPE})
        endif()
    endif()

    if(NOT TARGET_NAME OR NOT TARGET ${TARGET_NAME})
        message(FATAL_ERROR "target_enable_debug_options() called without valid TARGET")
    endif()

    if(NOT SCOPE_NAME IN_LIST CMAKE_TARGET_SCOPE_TYPES)
        message(FATAL_ERROR "Invalid SCOPE_NAME '${SCOPE_NAME}' for target_enable_debug_options()")
    endif()

    get_current_compiler(CURRENT_COMPILER)

    # Set default debug info level if not specified
    if(NOT DEFINED ARG_DEBUG_INFO_LEVEL)
        set(ARG_DEBUG_INFO_LEVEL 2)  # Default to level 2 (good balance of info vs size)
    endif()

    message(STATUS "Configuring debug options for target '${TARGET_NAME}' (${CURRENT_COMPILER})")

    if("${CURRENT_COMPILER}" STREQUAL "MSVC")
        _configure_msvc_debug_options(${TARGET_NAME} ${SCOPE_NAME} 
            ${ARG_ENABLE_EDIT_AND_CONTINUE} ${ARG_ENABLE_DEBUG_INFO})
    elseif("${CURRENT_COMPILER}" MATCHES "Clang.*|GCC")
        _configure_gcc_clang_debug_options(${TARGET_NAME} ${SCOPE_NAME} 
            ${ARG_ENABLE_DEBUG_INFO} ${ARG_DEBUG_INFO_LEVEL})
    else()
        message(STATUS "Debug options not configured for compiler: ${CURRENT_COMPILER}")
    endif()
endfunction()

#
# Enable debug options globally for all targets
#
# Usage:
# enable_global_debug_options(
#   [ENABLE_EDIT_AND_CONTINUE]
#   [ENABLE_DEBUG_INFO] 
#   [DEBUG_INFO_LEVEL level]
# )
function(enable_global_debug_options)
    cmake_parse_arguments(ARG 
        "ENABLE_EDIT_AND_CONTINUE;ENABLE_DEBUG_INFO" 
        "DEBUG_INFO_LEVEL" 
        "" 
        ${ARGN}
    )

    # Check if already applied globally
    get_property(already_applied GLOBAL PROPERTY PROJECT_GLOBAL_DEBUG_OPTIONS_ENABLED)
    if(already_applied)
        message(STATUS "Global debug options already applied, skipping")
        return()
    endif()

    get_current_compiler(CURRENT_COMPILER)

    # Set default debug info level if not specified
    if(NOT DEFINED ARG_DEBUG_INFO_LEVEL)
        set(ARG_DEBUG_INFO_LEVEL 2)
    endif()

    message(STATUS "Applying global debug options for all targets (${CURRENT_COMPILER})")

    if("${CURRENT_COMPILER}" STREQUAL "MSVC")
        _configure_global_msvc_debug_options(${ARG_ENABLE_EDIT_AND_CONTINUE} ${ARG_ENABLE_DEBUG_INFO})
    elseif("${CURRENT_COMPILER}" MATCHES "Clang.*|GCC")
        _configure_global_gcc_clang_debug_options(${ARG_ENABLE_DEBUG_INFO} ${ARG_DEBUG_INFO_LEVEL})
    else()
        message(STATUS "Global debug options not configured for compiler: ${CURRENT_COMPILER}")
    endif()

    set_property(GLOBAL PROPERTY PROJECT_GLOBAL_DEBUG_OPTIONS_ENABLED TRUE)
endfunction()

#
# Private function to configure MSVC debug options for a target
#
function(_configure_msvc_debug_options TARGET_NAME SCOPE_NAME ENABLE_EDIT_AND_CONTINUE ENABLE_DEBUG_INFO)
    set(DEBUG_OPTIONS "")

    if(ENABLE_EDIT_AND_CONTINUE)
        # /ZI enables Edit and Continue (Program Database for Edit and Continue)
        # This is more powerful than /Zi but has some limitations and larger file sizes
        list(APPEND DEBUG_OPTIONS "/ZI")
        message(STATUS "  - Edit and Continue: enabled (/ZI)")
        
        # Edit and Continue requires incremental linking
        target_link_options(${TARGET_NAME} ${SCOPE_NAME} "/INCREMENTAL")
        message(STATUS "  - Incremental linking: enabled (required for Edit and Continue)")
        
        # Edit and Continue is incompatible with some security features
        # Remove conflicting flags that may have been added by hardening
        get_target_property(EXISTING_COMPILE_OPTIONS ${TARGET_NAME} COMPILE_OPTIONS)
        if(EXISTING_COMPILE_OPTIONS)
            list(FILTER EXISTING_COMPILE_OPTIONS EXCLUDE REGEX "/guard:cf")
            set_target_properties(${TARGET_NAME} PROPERTIES COMPILE_OPTIONS "${EXISTING_COMPILE_OPTIONS}")
            message(STATUS "  - Control Flow Guard disabled (incompatible with Edit and Continue)")
        endif()
        
        # Also remove /guard:cf from any compile options that might be added later
        target_compile_options(${TARGET_NAME} ${SCOPE_NAME} "/guard:cf-")
        
    elseif(ENABLE_DEBUG_INFO)
        # /Zi enables debug information (Program Database)
        list(APPEND DEBUG_OPTIONS "/Zi")
        message(STATUS "  - Debug information: enabled (/Zi)")
    endif()

    if(DEBUG_OPTIONS)
        target_compile_options(${TARGET_NAME} ${SCOPE_NAME} ${DEBUG_OPTIONS})
    endif()
endfunction()

#
# Private function to configure GCC/Clang debug options for a target
#
function(_configure_gcc_clang_debug_options TARGET_NAME SCOPE_NAME ENABLE_DEBUG_INFO DEBUG_INFO_LEVEL)
    set(DEBUG_OPTIONS "")

    if(ENABLE_DEBUG_INFO)
        # Configure debug information level
        if(DEBUG_INFO_LEVEL EQUAL 0)
            list(APPEND DEBUG_OPTIONS "-g0")
            message(STATUS "  - Debug information: disabled (-g0)")
        elseif(DEBUG_INFO_LEVEL EQUAL 1)
            list(APPEND DEBUG_OPTIONS "-g1")
            message(STATUS "  - Debug information: minimal (-g1)")
        elseif(DEBUG_INFO_LEVEL EQUAL 2)
            list(APPEND DEBUG_OPTIONS "-g2")
            message(STATUS "  - Debug information: default (-g2)")
        elseif(DEBUG_INFO_LEVEL EQUAL 3)
            list(APPEND DEBUG_OPTIONS "-g3")
            message(STATUS "  - Debug information: maximum (-g3)")
        else()
            list(APPEND DEBUG_OPTIONS "-g")
            message(STATUS "  - Debug information: default (-g)")
        endif()
    endif()

    if(DEBUG_OPTIONS)
        target_compile_options(${TARGET_NAME} ${SCOPE_NAME} ${DEBUG_OPTIONS})
    endif()
endfunction()

#
# Private function to configure global MSVC debug options
#
function(_configure_global_msvc_debug_options ENABLE_EDIT_AND_CONTINUE ENABLE_DEBUG_INFO)
    if(ENABLE_EDIT_AND_CONTINUE)
        # Apply Edit and Continue globally
        set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /ZI" CACHE STRING "Global CXX Debug flags with Edit and Continue" FORCE)
        set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} /ZI" CACHE STRING "Global C Debug flags with Edit and Continue" FORCE)
        
        # Enable incremental linking for debug builds
        set(CMAKE_EXE_LINKER_FLAGS_DEBUG "${CMAKE_EXE_LINKER_FLAGS_DEBUG} /INCREMENTAL" CACHE STRING "Global EXE linker Debug flags for Edit and Continue" FORCE)
        set(CMAKE_SHARED_LINKER_FLAGS_DEBUG "${CMAKE_SHARED_LINKER_FLAGS_DEBUG} /INCREMENTAL" CACHE STRING "Global SHARED linker Debug flags for Edit and Continue" FORCE)
        
        message(STATUS "  - Global Edit and Continue: enabled (/ZI)")
        message(STATUS "  - Global incremental linking: enabled (Debug builds)")
        
    elseif(ENABLE_DEBUG_INFO)
        # Apply basic debug info globally
        set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /Zi" CACHE STRING "Global CXX Debug flags with debug info" FORCE)
        set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} /Zi" CACHE STRING "Global C Debug flags with debug info" FORCE)
        
        message(STATUS "  - Global debug information: enabled (/Zi)")
    endif()
endfunction()

#
# Private function to configure global GCC/Clang debug options
#
function(_configure_global_gcc_clang_debug_options ENABLE_DEBUG_INFO DEBUG_INFO_LEVEL)
    if(ENABLE_DEBUG_INFO)
        set(DEBUG_FLAG "")
        
        if(DEBUG_INFO_LEVEL EQUAL 0)
            set(DEBUG_FLAG "-g0")
            message(STATUS "  - Global debug information: disabled (-g0)")
        elseif(DEBUG_INFO_LEVEL EQUAL 1)
            set(DEBUG_FLAG "-g1")
            message(STATUS "  - Global debug information: minimal (-g1)")
        elseif(DEBUG_INFO_LEVEL EQUAL 2)
            set(DEBUG_FLAG "-g2")
            message(STATUS "  - Global debug information: default (-g2)")
        elseif(DEBUG_INFO_LEVEL EQUAL 3)
            set(DEBUG_FLAG "-g3")
            message(STATUS "  - Global debug information: maximum (-g3)")
        else()
            set(DEBUG_FLAG "-g")
            message(STATUS "  - Global debug information: default (-g)")
        endif()

        if(DEBUG_FLAG)
            set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} ${DEBUG_FLAG}" CACHE STRING "Global CXX Debug flags with debug info" FORCE)
            set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} ${DEBUG_FLAG}" CACHE STRING "Global C Debug flags with debug info" FORCE)
        endif()
    endif()
endfunction()
