include(CMakeParseArguments)

#
# Enable sanitizers for the targets
# usage:
# targets_enable_sanitizers(
#   TARGETS <target ...>
#   [SCOPE] <INTERFACE|PRIVATE|PUBLIC> # scope of the target
#   [ENABLE_SANITIZER_ADDRESS]
#   [ENABLE_SANITIZER_LEAK]
#   [ENABLE_SANITIZER_UNDEFINED_BEHAVIOR]
#   [ENABLE_SANITIZER_THREAD]
#   [ENABLE_SANITIZER_MEMORY]
#   [ENABLE_SANITIZER_FUZZER]
#   [ENABLE_SANITIZER_ALL]
#   HAVE_SANITIZER # output variable to check if the sanitizer is supported
# )
function(
    targets_enable_sanitizers
)
    set(oneValueArgs
        SCOPE
        ENABLE_SANITIZER_ADDRESS
        ENABLE_SANITIZER_LEAK
        ENABLE_SANITIZER_UNDEFINED_BEHAVIOR
        ENABLE_SANITIZER_THREAD
        ENABLE_SANITIZER_MEMORY
        ENABLE_SANITIZER_FUZZER
        ENABLE_SANITIZER_ALL
        HAVE_SANITIZER
    )
    set(multiValueArgs
        TARGETS
    )
    cmake_parse_arguments(
        ARG
        ""
        "${oneValueArgs}"
        "${multiValueArgs}"
        ${ARGN}
    )

    get_current_compiler(CURRENT_COMPILER)

    #

    # if ARG_SCOPE is not set, error
    if (NOT ARG_SCOPE)
        message(FATAL_ERROR "No scope specified")
    endif()

    # if ARG_SCOPE is not (PRIVATE|PUBLIC|INTERFACE), error
    if (NOT ARG_SCOPE MATCHES "PRIVATE|PUBLIC|INTERFACE")
        message(FATAL_ERROR "Invalid scope specified: ${ARG_SCOPE}")
    endif()
    
    if (${ENABLE_SANITIZER_ALL})
        set(ARG_ENABLE_SANITIZER_ADDRESS ON)
        set(ARG_ENABLE_SANITIZER_LEAK ON)
        set(ARG_ENABLE_SANITIZER_UNDEFINED_BEHAVIOR ON)
        set(ARG_ENABLE_SANITIZER_THREAD ON)
        set(ARG_ENABLE_SANITIZER_MEMORY ON)
        set(ARG_ENABLE_SANITIZER_FUZZER ON)
    endif()

    _try_add_sanitizer(SANITIZER_FLAGS
        COMPILER_TYPE ${CURRENT_COMPILER}
        SANITIZER_NAME "address"
        ADD_CONDITION ${ARG_ENABLE_SANITIZER_ADDRESS}
    )
    _try_add_sanitizer(SANITIZER_FLAGS 
        COMPILER_TYPE ${CURRENT_COMPILER}
        SANITIZER_NAME "leak"
        ADD_CONDITION ${ARG_ENABLE_SANITIZER_LEAK}
    )
    _try_add_sanitizer(SANITIZER_FLAGS 
        COMPILER_TYPE ${CURRENT_COMPILER}
        SANITIZER_NAME "undefined"
        ADD_CONDITION ${ARG_ENABLE_SANITIZER_UNDEFINED_BEHAVIOR}
    )
    _try_add_sanitizer(SANITIZER_FLAGS 
        COMPILER_TYPE ${CURRENT_COMPILER}
        SANITIZER_NAME "thread"
        ADD_CONDITION ${ARG_ENABLE_SANITIZER_THREAD}
    )
    _try_add_sanitizer(SANITIZER_FLAGS 
        COMPILER_TYPE ${CURRENT_COMPILER}
        SANITIZER_NAME "memory"
        ADD_CONDITION ${ARG_ENABLE_SANITIZER_MEMORY}
    )
    _try_add_sanitizer(SANITIZER_FLAGS 
        COMPILER_TYPE ${CURRENT_COMPILER}
        SANITIZER_NAME "fuzzer"
        ADD_CONDITION ${ARG_ENABLE_SANITIZER_FUZZER}
    )

    #

    # if no sanitizers are enabled, return
    if ("${SANITIZER_FLAGS}" STREQUAL "")
        message(STATUS "No sanitizers enabled")

        set(${ARG_HAVE_SANITIZER} FALSE PARENT_SCOPE)
        return()
    endif()
    message(STATUS "Sanitizers enabled: ${SANITIZER_FLAGS}")

    foreach (target ${ARG_TARGETS})
        if (NOT target)
            message(FATAL_ERROR "No target specified")
        endif()

        if (NOT TARGET ${target})
            message(FATAL_ERROR "Target ${target} not found")
        endif()

        target_compile_options(${target} ${ARG_SCOPE} ${SANITIZER_FLAGS})

        if ("${CURRENT_COMPILER}" STREQUAL "MSVC")
            string(FIND "$ENV{PATH}" "$ENV{VSINSTALLDIR}" INDEX_OF_VS_INSTALL_DIR)
            if ("${INDEX_OF_VS_INSTALL_DIR}" STREQUAL "-1")
                message(SEND_ERROR
                    "Using MSVC sanitizers requires setting the MSVC environment before building the project. Please manually open the MSVC command prompt and rebuild the project."
                )
            endif()

            target_compile_definitions(${target} ${ARG_SCOPE} _DISABLE_VECTOR_ANNOTATION _DISABLE_STRING_ANNOTATION)
            target_link_options(${target} ${ARG_SCOPE} /INCREMENTAL:NO)

        else()
            target_link_options(${target} ${ARG_SCOPE} ${SANITIZER_FLAGS})
        endif()
     endforeach()

     # Set the output variable in the parent scope
     set(${ARG_HAVE_SANITIZER} TRUE PARENT_SCOPE)
endfunction()

#
# Try to add sanitizer to the list if the compiler supports it
# usage:
# try_add_sanitizer(
#   <output_list>
#   COMPILER_TYPE <compiler_type>
#   [SANITIZER_NAME] <address|leak|undefined|thread|memory|fuzzer>
#   [ADD_CONDITION] <condition> # condition to add the sanitizer
# )
#
function(_try_add_sanitizer OUTPUT_VARIABLE)
    set(oneValueArgs
        COMPILER_TYPE
        SANITIZER_NAME
        ADD_CONDITION
    )
    cmake_parse_arguments(
        ARG
        ""
        "${oneValueArgs}"
        ""
        "${ARGN}"
    )
    
    # Check if the condition is met
    if (NOT ARG_ADD_CONDITION OR "${ARG_ADD_CONDITION}" STREQUAL "OFF")
        return()
    endif()

    # Check if the compiler type is supported
    if ("${ARG_COMPILER_TYPE}" STREQUAL "MSVC")
		check_cxx_compiler_flag(/fsanitize=${ARG_SANITIZER_NAME} HAVE_SANITIZER)
    elseif ("${ARG_COMPILER_TYPE}" MATCHES "Clang|GCC")
        check_cxx_compiler_flag(-fsanitize=${ARG_SANITIZER_NAME} HAVE_SANITIZER)
    endif()

    # Check if the sanitizer is supported
    if (NOT HAVE_SANITIZER)
        message(WARNING "Sanitizer ${ARG_SANITIZER_NAME} is not supported with ${ARG_COMPILER_TYPE}")
        return()
    endif()

    if ("${ARG_COMPILER_TYPE}" STREQUAL "MSVC")
        # if CURRENT_FLAGS is empty, set it to /fsanitize=${ARG_SANITIZER_NAME}, else append to it
        if ("${${OUTPUT_VARIABLE}}" STREQUAL "")
            set(${OUTPUT_VARIABLE} "/fsanitize=${ARG_SANITIZER_NAME}" PARENT_SCOPE)
        else()
            set(${OUTPUT_VARIABLE} "${${OUTPUT_VARIABLE}} /fsanitize=${ARG_SANITIZER_NAME}" PARENT_SCOPE)
        endif()
    else()
        # if CURRENT_FLAGS is empty, set it to -fsanitize=${ARG_SANITIZER_NAME}, else append to it
        if ("${${OUTPUT_VARIABLE}}" STREQUAL "")
            set(${OUTPUT_VARIABLE} "-fsanitize=${ARG_SANITIZER_NAME}" PARENT_SCOPE)
        else()
            set(${OUTPUT_VARIABLE} "${${OUTPUT_VARIABLE}},${ARG_SANITIZER_NAME}" PARENT_SCOPE)
        endif()
    endif()

endfunction()
