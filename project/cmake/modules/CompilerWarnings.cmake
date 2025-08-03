include(GetCurrentCompiler)

#
# from here:
#
# https://github.com/lefticus/cppbestpractices/blob/master/02-Use_the_Tools_Available.md

#
# Set compiler warnings
# usage:
# target_add_compiler_warnings(
#   TARGET_NAME
#   [SCOPE_NAME]
#   [MSVC_WARNINGS] (string)
#   [CLANG_WARNINGS] (string)
#   [GCC_WARNINGS] (string)
#   [EMSCRIPTEN_WARNINGS] (string)
#   WARNINGS_AS_ERRORS [ON/OFF]
# )
#
function(target_add_compiler_warnings TARGET_NAME SCOPE_NAME)
    # Parse the options first
    set(oneValueArgs
        WARNINGS_AS_ERRORS
    )
    set(multiValueArgs
        MSVC_WARNINGS
        CLANG_WARNINGS
        GCC_WARNINGS
        EMSCRIPTEN_WARNINGS
    )
    cmake_parse_arguments(
        ARG
        ""
        ${oneValueArgs}
        ${multiValueArgs}
        ${ARGN}
    )

    get_current_compiler(CURRENT_COMPILER)

    #

    if(NOT TARGET_NAME OR NOT TARGET ${TARGET_NAME})
        message(FATAL_ERROR "target_add_compiler_warnings() called without TARGET")
    endif()

    if(NOT SCOPE_NAME)
        set(SCOPE_NAME PRIVATE)
    elseif(${SCOPE_NAME} IN_LIST CMAKE_TARGET_SCOPE_TYPES)
        set(SCOPE_NAME ${SCOPE_NAME})
    else()
        message(FATAL_ERROR "target_add_compiler_warnings() called with invalid SCOPE: ${SCOPE_NAME}")
    endif()

    if("${CURRENT_COMPILER}" STREQUAL "MSVC")
        if(ARG_MSVC_WARNINGS)
            set(PROJECT_WARNINGS_CXX "${ARG_MSVC_WARNINGS}")
        else()
            set(PROJECT_WARNINGS_CXX
                /W4 # Baseline reasonable warnings
                /w14189 # 'identifier': local variable is initialized but not referenced
                /w14242 # 'identifier': conversion from 'type1' to 'type2', possible loss of data
                /w14254 # 'operator': conversion from 'type1:field_bits' to 'type2:field_bits', possible loss of data
                /w14263 # 'function': member function does not override any base class virtual member function
                /w14265 # 'classname': class has virtual functions, but destructor is not virtual instances of this class may not
                                # be destructed correctly
                /w14287 # 'operator': unsigned/negative constant mismatch
                /we4289 # nonstandard extension used: 'variable': loop control variable declared in the for-loop is used outside
                                # the for-loop scope
                /w14296 # 'operator': expression is always 'boolean_value'
                /w14311 # 'variable': pointer truncation from 'type1' to 'type2'
                /w14545 # expression before comma evaluates to a function which is missing an argument list
                /w14546 # function call before comma missing argument list
                /w14547 # 'operator': operator before comma has no effect; expected operator with side-effect
                /w14549 # 'operator': operator before comma has no effect; did you intend 'operator'?
                /w14555 # expression has no effect; expected expression with side- effect
                /w14619 # pragma warning: there is no warning number 'number'
                /w14640 # Enable warning on thread un-safe static member initialization
                /w14826 # Conversion from 'type1' to 'type2' is sign-extended. This may cause unexpected runtime behavior.
                /w14905 # wide string literal cast to 'LPSTR'
                /w14906 # string literal cast to 'LPWSTR'
                /w14928 # illegal copy-initialization; more than one user-defined conversion has been implicitly applied
                /permissive- # standards conformance mode for MSVC compiler.
            )
        endif()

        if(ARG_WARNINGS_AS_ERRORS)
            message(TRACE "Warnings are treated as errors")
            list(APPEND PROJECT_WARNINGS_CXX /WX /sdl)
        endif()

    elseif("${CURRENT_COMPILER}" MATCHES "CLANG.*")
        if(ARG_CLANG_WARNINGS)
            set(PROJECT_WARNINGS_CXX "${ARG_CLANG_WARNINGS}")
        else()
            set(PROJECT_WARNINGS_CXX
                -Wall
                -Wextra # reasonable and standard
                -Wshadow # warn the user if a variable declaration shadows one from a parent context
                -Wnon-virtual-dtor # warn the user if a class with virtual functions has a non-virtual destructor. This helps
                # catch hard to track down memory errors
                -Wold-style-cast # warn for c-style casts
                -Wcast-align # warn for potential performance problem casts
                -Wunused # warn on anything being unused
                -Woverloaded-virtual # warn if you overload (not override) a virtual function
                -Wpedantic # warn if non-standard C++ is used
                -Wconversion # warn on type conversions that may lose data
                -Wsign-conversion # warn on sign conversions
                -Wnull-dereference # warn if a null dereference is detected
                -Wdouble-promotion # warn if float is implicit promoted to double
                -Wformat=2 # warn on security issues around functions that format output (ie printf)
                -Wimplicit-fallthrough # warn on statements that fallthrough without an explicit annotation
                -Wno-error=unused-command-line-argument # ignore unused command line arguments warning
                -Wno-error=unknown-argument # ignore unknown command line arguments warning
                -Wno-c++98-compat -Wno-c++98-compat-pedantic # ignore C++98 compatibility warnings
            )
        endif()

        if(ARG_WARNINGS_AS_ERRORS)
            message(TRACE "Warnings are treated as errors")
            list(APPEND PROJECT_WARNINGS_CXX -Werror)
        endif()

    elseif("${CURRENT_COMPILER}" STREQUAL "GCC")

        if(ARG_GCC_WARNINGS)
            set(PROJECT_WARNINGS_CXX "${ARG_GCC_WARNINGS}")
        else()
            set(PROJECT_WARNINGS_CXX
                -Wall
                -Wextra # reasonable and standard
                -Wshadow # warn the user if a variable declaration shadows one from a parent context
                -Wnon-virtual-dtor # warn the user if a class with virtual functions has a non-virtual destructor. This helps
                # catch hard to track down memory errors
                -Wold-style-cast # warn for c-style casts
                -Wcast-align # warn for potential performance problem casts
                -Wunused # warn on anything being unused
                -Woverloaded-virtual # warn if you overload (not override) a virtual function
                -Wpedantic # warn if non-standard C++ is used
                -Wconversion # warn on type conversions that may lose data
                -Wsign-conversion # warn on sign conversions
                -Wnull-dereference # warn if a null dereference is detected
                -Wdouble-promotion # warn if float is implicit promoted to double
                -Wformat=2 # warn on security issues around functions that format output (ie printf)
                -Wimplicit-fallthrough # warn on statements that fallthrough without an explicit annotation
                -Wmisleading-indentation # warn if indentation implies blocks where blocks do not exist
                -Wduplicated-cond # warn if if / else chain has duplicated conditions
                -Wduplicated-branches # warn if if / else branches have duplicated code
                -Wlogical-op # warn about logical operations being used where bitwise were probably wanted
                -Wuseless-cast # warn if you perform a cast to the same type
                -Wno-error=unused-command-line-argument # ignore unused command line arguments warning
                -Wno-error=unknown-argument # ignore unknown command line arguments warning
                -Wno-c++98-compat -Wno-c++98-compat-pedantic # ignore C++98 compatibility warnings
            )
        endif()

        if(ARG_WARNINGS_AS_ERRORS)
            message(TRACE "Warnings are treated as errors")
            list(APPEND PROJECT_WARNINGS_CXX -Werror)
        endif()
    
    elseif("${CURRENT_COMPILER}" STREQUAL "EMSCRIPTEN")
        if(ARG_EMSCRIPTEN_WARNINGS)
            set(PROJECT_WARNINGS_CXX "${ARG_EMSCRIPTEN_WARNINGS}")
        else()
            set(PROJECT_WARNINGS_CXX
                -Wall # all warnings
                -Wextra # extra warnings
                -Wshadow # warn the user if a variable declaration shadows one from a parent context
                -Wnon-virtual-dtor # warn the user if a class with virtual functions has a non-virtual destructor. This helps
                -Wold-style-cast # warn for c-style casts
                -Wcast-align # warn for potential performance problem casts
                -Wunused # warn on anything being unused
                -Woverloaded-virtual # warn if you overload (not override) a virtual function
                -Wpedantic # warn if non-standard C++ is used
                -Wconversion # warn on type conversions that may lose data
                -Wsign-conversion # warn on sign conversions
                -Wnull-dereference # warn if a null dereference is detected
                -Wdouble-promotion # warn if float is implicit promoted to double
                -Wformat=2 # warn on security issues around functions that format output (ie printf)
                -Wimplicit-fallthrough # warn on statements that fallthrough without an explicit annotation
                -Wmisleading-indentation # warn if indentation implies blocks where blocks do not exist
                -Wno-unused-command-line-argument # ignore unused command line arguments warning
                -Wno-unknown-argument # ignore unknown command line arguments warning
                -Wno-c++98-compat -Wno-c++98-compat-pedantic # ignore C++98 compatibility warnings
            )
        endif()

        if(ARG_WARNINGS_AS_ERRORS)
            message(TRACE "Warnings are treated as errors")
            list(APPEND PROJECT_WARNINGS_CXX -Werror)
        endif()
    endif()

    # set the warnings for all targets
    foreach(target ${ARG_TARGETS})
        target_compile_options(
            ${target}
            PRIVATE
            $<$<COMPILE_LANGUAGE:CXX>:${PROJECT_WARNINGS_CXX}>
            $<$<COMPILE_LANGUAGE:C>:${PROJECT_WARNINGS_CXX}>
        )
    endforeach()
endfunction()

#
# Configure exception handling for targets
# usage:
# target_configure_exceptions(TARGET_NAME SCOPE_NAME)
#
function(target_configure_exceptions TARGET_NAME SCOPE_NAME)
    get_current_compiler(CURRENT_COMPILER)

    if (NOT TARGET ${TARGET_NAME})
        message(FATAL_ERROR "target_configure_exceptions() called without a TARGET")
    endif()

    if(NOT ${SCOPE_NAME} IN_LIST CMAKE_TARGET_SCOPE_TYPES)
        message(FATAL_ERROR "target_add_compiler_warnings() called with invalid SCOPE: ${SCOPE_NAME}")
    endif()

    set(EXCEPTION_FLAGS "")
    if (${CURRENT_COMPILER} MATCHES "MSVC")
        if (ENABLE_EXCEPTIONS)
            list(APPEND EXCEPTION_FLAGS /EHsc)
        else()
            list(APPEND EXCEPTION_FLAGS /EHsc-)
        endif()
    elseif (${CURRENT_COMPILER} MATCHES "CLANG.*|GCC")
        if (ENABLE_EXCEPTIONS)
            list(APPEND EXCEPTION_FLAGS -fexceptions)
        else()
            list(APPEND EXCEPTION_FLAGS -fno-exceptions)
        endif()
    elseif ("${CURRENT_COMPILER}" STREQUAL "EMSCRIPTEN")
        if (ENABLE_EXCEPTIONS)
            list(APPEND EXCEPTION_FLAGS -fexceptions)
        else()
            list(APPEND EXCEPTION_FLAGS -fno-exceptions) 
        endif()
    endif()

    if(EXCEPTION_FLAGS)
        target_compile_options(
            ${TARGET_NAME}
            ${SCOPE_NAME}
            $<$<COMPILE_LANGUAGE:CXX>:${EXCEPTION_FLAGS}>
        )
        message(TRACE "Applied exception flags '${EXCEPTION_FLAGS}' to target '${TARGET_NAME}'")
    endif()
endfunction()
