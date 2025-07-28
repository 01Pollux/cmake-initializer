include(TargetAddCompilerWarnings)
include(TargetHardening)
include(TargetSanitizers)
include(StaticAnalysis)
include(StaticLinking)
include(TargetDebugOptions)

# Apply common project options directly to a TARGET_NAME
# Usage:
# target_setup_common_options(
#   target_name
#   [PRIVATE|PUBLIC|INTERFACE]
# )
function(target_setup_common_options TARGET_NAME SCOPE_NAME)
    if(NOT TARGET_NAME OR NOT TARGET ${TARGET_NAME})
        message(FATAL_ERROR "target_setup_common_options: TARGET_NAME argument is required")
    endif()

    if(NOT SCOPE_NAME)
        set(SCOPE_NAME PRIVATE)
    elseif(NOT ${SCOPE_NAME} IN_LIST CMAKE_TARGET_SCOPE_TYPES)
        message(FATAL_ERROR "target_setup_common_options: Invalid SCOPE_NAME '${SCOPE_NAME}' specified. Must be one of: ${CMAKE_TARGET_SCOPE_TYPES}.")
    endif()

    # Enable IPO optimization if needed
    if(ENABLE_IPO)
        include(EnableInterproceduralOptimization)
        set_target_properties(${TARGET_NAME} PROPERTIES INTERPROCEDURAL_OPTIMIZATION TRUE)
    endif()

    # Set compiler warning flags
    target_add_compiler_warnings(
        ${TARGET_NAME}
        ${SCOPE_NAME}
        WARNINGS_AS_ERRORS ${ENABLE_WARNINGS_AS_ERRORS}
    )

    # Enable sanitizers if needed (only if not already applied globally)
    if(ENABLE_SANITIZERS)
        # Check if global sanitizers are enabled by looking for address sanitizer in CMAKE_CXX_FLAGS
        string(FIND "${CMAKE_CXX_FLAGS}" "/fsanitize" GLOBAL_SANITIZERS_INDEX)
        if(GLOBAL_SANITIZERS_INDEX EQUAL -1)
            # Global sanitizers not found, apply per-target
            target_enable_sanitizers(
                ${TARGET_NAME}
                ${SCOPE_NAME}
                ENABLE_SANITIZER_ADDRESS ${ENABLE_ASAN}
                ENABLE_SANITIZER_LEAK ${ENABLE_LSAN}
                ENABLE_SANITIZER_UNDEFINED_BEHAVIOR ${ENABLE_UBSAN}
                ENABLE_SANITIZER_THREAD ${ENABLE_TSAN}
                ENABLE_SANITIZER_MEMORY ${ENABLE_MSAN}
            )
        else()
            message(STATUS "Global sanitizers already applied for ${TARGET_NAME}")
            
            # If this is an executable and AddressSanitizer is enabled, copy the runtime DLL
            get_target_property(TARGET_TYPE ${TARGET_NAME} TYPE)
            if(TARGET_TYPE STREQUAL "EXECUTABLE" AND ENABLE_ASAN)
                get_property(ASAN_DLL_PATH GLOBAL PROPERTY ASAN_RUNTIME_DLL_PATH)
                if(ASAN_DLL_PATH)
                    add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
                        COMMAND ${CMAKE_COMMAND} -E copy_if_different
                        "${ASAN_DLL_PATH}"
                        "$<TARGET_FILE_DIR:${TARGET_NAME}>"
                        COMMENT "Copying AddressSanitizer runtime DLL for ${TARGET_NAME}")
                endif()
            endif()
        endif()
    endif()

    # Enable static linking if needed
    if(ENABLE_STATIC_RUNTIME)
        target_enable_static_linking(${TARGET_NAME} ${SCOPE_NAME})
    endif()

    # Enable unity build if needed
    set_target_properties(
        ${TARGET_NAME}
        PROPERTIES
        UNITY_BUILD ${ENABLE_UNITY_BUILD}
    )

    # Enable project hardening if needed (only if not already applied globally)
    get_property(global_hardening_enabled GLOBAL PROPERTY PROJECT_GLOBAL_HARDENING_ENABLED)
    if(ENABLE_HARDENING AND NOT global_hardening_enabled)
        target_enable_hardening(${TARGET_NAME} ${SCOPE_NAME})
    endif()

    # Enable static analysis if needed
    if(ENABLE_CLANG_TIDY OR ENABLE_CPPCHECK)
        target_enable_static_analysis(${TARGET_NAME} ${SCOPE_NAME})
    endif()

    # Enable debug options if needed (only if not already applied globally)
    get_property(global_debug_enabled GLOBAL PROPERTY PROJECT_GLOBAL_DEBUG_OPTIONS_ENABLED)
    if((ENABLE_EDIT_AND_CONTINUE OR ENABLE_DEBUG_INFO) AND NOT global_debug_enabled)
        set(DEBUG_ARGS ${SCOPE_NAME})
        if(ENABLE_EDIT_AND_CONTINUE)
            list(APPEND DEBUG_ARGS "ENABLE_EDIT_AND_CONTINUE")
        endif()
        if(ENABLE_DEBUG_INFO)
            list(APPEND DEBUG_ARGS "ENABLE_DEBUG_INFO")
        endif()
        list(APPEND DEBUG_ARGS "DEBUG_INFO_LEVEL" "${DEBUG_INFO_LEVEL}")
        
        target_enable_debug_options(${TARGET_NAME} ${DEBUG_ARGS})
    endif()

    # Set PCH headers if needed
    if(ENABLE_PCH)
        target_precompile_headers(
            ${TARGET_NAME}
            ${SCOPE_NAME}
            <vector>
            <string>
            <utility>
            <algorithm>
        )
    endif()

    # Link to config TARGET_NAME for project configuration
    target_link_libraries(${TARGET_NAME} ${SCOPE_NAME} ${THIS_PROJECT_NAMESPACE}::config)
    
    # Check if Dependencies.cmake exists and include it
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/Dependencies.cmake")
        include(Dependencies.cmake)
    endif()
    
    # Check if target_load_dependencies function exists and call it
    if(COMMAND target_load_dependencies)
        target_load_dependencies(${TARGET_NAME})
    else()
        message(WARNING "DEPENDENCIES option specified but target_load_dependencies function not found. Make sure Dependencies.cmake is present and defines this function.")
    endif()
endfunction()
