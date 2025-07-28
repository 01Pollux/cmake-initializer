#
# Include a system directory (which suppresses its warnings).
#
# Usage:
# target_include_system_directories(
#     TARGET_NAME
#     INTERFACE|PUBLIC|PRIVATE
#     <include_dir1> <include_dir2> ...
# )
function(target_include_system_directories TARGET_NAME)
    set(multiValueArgs INTERFACE PUBLIC PRIVATE)
    cmake_parse_arguments(
        ARG
        ""
        ""
        "${multiValueArgs}"
        ${ARGN})

    foreach(scope IN ITEMS INTERFACE PUBLIC PRIVATE)
        foreach(lib_include_dirs IN LISTS ARG_${scope})
            if(${scope} STREQUAL "INTERFACE" OR ${scope} STREQUAL "PUBLIC")
                target_include_directories(
                    ${TARGET_NAME}
                    SYSTEM
                    ${scope}
                    "$<BUILD_INTERFACE:${lib_include_dirs}>"
                    "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/$<TARGET_NAME:${TARGET_NAME}>>")
            else()
                target_include_directories(
                    ${TARGET_NAME}
                    SYSTEM
                    ${scope}
                    ${lib_include_dirs})
            endif()
        endforeach()
    endforeach()

endfunction()

#
# Include the directories of a library target as system directories (which suppresses their warnings).
#
# Usage:
# target_include_system_library(
#     TARGET_NAME
#     INTERFACE|PUBLIC|PRIVATE
#     <lib>
# )
function(
    target_include_system_library
    TARGET_NAME
    SCOPE_NAME
    lib)
    # check if this is a target
    if(TARGET ${lib})
        get_target_property(lib_include_dirs ${lib} INTERFACE_INCLUDE_DIRECTORIES)
        if(lib_include_dirs)
            target_include_system_directories(${TARGET_NAME} ${SCOPE_NAME} ${lib_include_dirs})
        else()
            message(TRACE "${lib} library does not have the INTERFACE_INCLUDE_DIRECTORIES property.")
        endif()
    endif()
endfunction()

#
# Link a library target as a system library (which suppresses its warnings).
#
# Usage:
# target_link_system_library(
#     TARGET_NAME
#     INTERFACE|PUBLIC|PRIVATE
#     <lib>
# )
function(
    target_link_system_library
    TARGET_NAME
    SCOPE_NAME
    lib)
    # Include the directories in the library
    target_include_system_library(${TARGET_NAME} ${SCOPE_NAME} ${lib})

    # Link the library
    target_link_libraries(${TARGET_NAME} ${SCOPE_NAME} ${lib})
endfunction()

#
# Link multiple library targets as system libraries (which suppresses their warnings).
#
# Usage:
# target_link_system_libraries(
#     TARGET_NAME
#     INTERFACE|PUBLIC|PRIVATE
#     <lib1> <lib2> ...
# )
function(target_link_system_libraries TARGET_NAME)
    set(multiValueArgs INTERFACE PUBLIC PRIVATE)
    cmake_parse_arguments(
        ARG
        ""
        ""
        "${multiValueArgs}"
        ${ARGN})

    foreach(scope IN ITEMS INTERFACE PUBLIC PRIVATE)
        foreach(lib IN LISTS ARG_${scope})
            target_link_system_library(${TARGET_NAME} ${scope} ${lib})
        endforeach()
    endforeach()
endfunction()
