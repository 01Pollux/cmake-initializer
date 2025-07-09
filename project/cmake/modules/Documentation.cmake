#
# Documentation generation support (Doxygen)
#
function(enable_documentation)
    set(options)
    set(oneValueArgs TARGET OUTPUT_DIR)
    set(multiValueArgs SOURCES)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    
    find_package(Doxygen QUIET)
    if(DOXYGEN_FOUND)
        set(DOXYGEN_OUTPUT_DIRECTORY ${ARG_OUTPUT_DIR})
        set(DOXYGEN_PROJECT_NAME ${THIS_PROJECT_PRETTY_NAME})
        set(DOXYGEN_PROJECT_NUMBER ${THIS_PROJECT_VERSION})
        set(DOXYGEN_PROJECT_BRIEF ${THIS_PROJECT_DESCRIPTION})
        set(DOXYGEN_GENERATE_HTML YES)
        set(DOXYGEN_GENERATE_XML YES)
        set(DOXYGEN_RECURSIVE YES)
        set(DOXYGEN_EXTRACT_ALL YES)
        set(DOXYGEN_HAVE_DOT NO)
        
        doxygen_add_docs(${ARG_TARGET}
            ${ARG_SOURCES}
            COMMENT "Generating documentation with Doxygen"
        )
        
        message(STATUS "** Documentation target '${ARG_TARGET}' added")
    else()
        message(WARNING "Doxygen not found - documentation generation disabled")
    endif()
endfunction()

option(ENABLE_DOCS "Enable documentation generation" OFF)
