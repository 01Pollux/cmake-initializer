#
# Static analysis tools setup (clang-tidy, cppcheck)
#
# Usage:
# target_enable_static_analysis(TARGET_NAME)
function(target_enable_static_analysis TARGET_NAME)
    if(NOT TARGET_NAME OR NOT TARGET ${TARGET_NAME})
        message(FATAL_ERROR "target_enable_static_analysis: Target '${TARGET_NAME}' does not exist")
        return()
    endif()

    # clang-tidy setup
    if(ENABLE_CLANG_TIDY)
        find_program(CLANG_TIDY_EXE NAMES "clang-tidy")
        if(CLANG_TIDY_EXE)
            message(STATUS "** clang-tidy found: ${CLANG_TIDY_EXE}")
            set_target_properties(${TARGET_NAME} PROPERTIES
                CXX_CLANG_TIDY "${CLANG_TIDY_EXE};--config-file=${CMAKE_SOURCE_DIR}/.clang-tidy;--header-filter=.*"
            )
            message(STATUS "** clang-tidy enabled for target: ${TARGET_NAME}")
        else()
            message(WARNING "clang-tidy requested but not found")
        endif()
    endif()

    # cppcheck setup
    if(ENABLE_CPPCHECK)
        find_program(CPPCHECK_EXE NAMES "cppcheck")
        if(CPPCHECK_EXE)
            message(STATUS "** cppcheck found: ${CPPCHECK_EXE}")
            set_target_properties(${TARGET_NAME} PROPERTIES
                CXX_CPPCHECK "${CPPCHECK_EXE};--enable=warning,performance,portability,information,missingInclude;--std=c++${CMAKE_CXX_STANDARD};--template=gcc;--verbose;--quiet"
            )
            message(STATUS "** cppcheck enabled for target: ${TARGET_NAME}")
        else()
            message(WARNING "cppcheck requested but not found")
        endif()
    endif()
endfunction()
