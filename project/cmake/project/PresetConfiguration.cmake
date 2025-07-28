# ==============================================================================
# Preset-Based Configuration System
# ==============================================================================
# This module handles automatic configuration based on CMake preset variables
# including test framework registration and CTest dashboard setup.

set(DEFAULT_TEST_FRAMEWORK "doctest" CACHE STRING "Default test framework to use if not specified")

# Auto-register test framework if DEFAULT_TEST_FRAMEWORK is defined in preset
function(_configure_preset_test_framework)
    if(DEFINED DEFAULT_TEST_FRAMEWORK AND BUILD_TESTING)
        message(STATUS "Auto-registering test framework from preset: ${DEFAULT_TEST_FRAMEWORK}")
        
        # Verify the framework is supported
        set(SUPPORTED_FRAMEWORKS "doctest" "catch2" "gtest" "boost")
        if(NOT DEFAULT_TEST_FRAMEWORK IN_LIST SUPPORTED_FRAMEWORKS)
            message(FATAL_ERROR "Unsupported test framework '${DEFAULT_TEST_FRAMEWORK}' in preset. Supported: ${SUPPORTED_FRAMEWORKS}")
        endif()
        
        # Check if framework is already registered to avoid duplicates
        get_property(already_registered GLOBAL PROPERTY TEST_FRAMEWORK_REGISTERED)
        if(NOT already_registered)
            register_test_framework(${DEFAULT_TEST_FRAMEWORK})
        else()
            message(STATUS "Test framework already registered, skipping auto-registration")
        endif()
    endif()
endfunction()

# Main preset configuration function - call this to apply all preset-based settings
function(configure_from_presets)
    message(STATUS "Configuring project from preset variables...")
    
    _configure_preset_test_framework()
    
    message(STATUS "Preset configuration completed")
endfunction()

configure_from_presets()
