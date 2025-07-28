include(CMakeParseArguments)

#
# Enable sanitizers for the targets
# usage:
# target_enable_sanitizers(
#   TARGET_NAME
#   PRIVATE|PUBLIC|INTERFACE
#   ENABLE_SANITIZER_ADDRESS]
#   ENABLE_SANITIZER_LEAK]
#   ENABLE_SANITIZER_UNDEFINED_BEHAVIOR]
#   ENABLE_SANITIZER_THREAD]
#   ENABLE_SANITIZER_MEMORY]
# )
function(target_enable_sanitizers TARGET_NAME SCOPE_NAME)
    if(NOT TARGET_NAME OR NOT TARGET ${TARGET_NAME})
        message(FATAL_ERROR "target_enable_sanitizers() called without TARGET")
    endif()
    if(NOT SCOPE_NAME)
        set(SCOPE_NAME PRIVATE)
    elseif(NOT ${SCOPE_NAME} IN_LIST CMAKE_TARGET_SCOPE_TYPES)
        message(FATAL_ERROR "Invalid SCOPE_NAME '${SCOPE_NAME}' for target_enable_sanitizers()")
    endif()

    set(oneValueArgs
        ENABLE_SANITIZER_ADDRESS
        ENABLE_SANITIZER_LEAK
        ENABLE_SANITIZER_UNDEFINED_BEHAVIOR
        ENABLE_SANITIZER_THREAD
        ENABLE_SANITIZER_MEMORY
    )
    cmake_parse_arguments(
        ARG
        ""
        ${oneValueArgs}
        ""
        ${ARGN}
    )

    get_current_compiler(CURRENT_COMPILER)

    # Sanitizers are primarily debugging tools and work best in Debug builds
    # In Release builds, they can cause performance issues and compilation problems
    if(CMAKE_BUILD_TYPE STREQUAL "Release")
        message(STATUS "Disabling sanitizers for ${TARGET_NAME} in Release mode (use Debug or RelWithDebInfo for sanitizers)")
        return()
    endif()

    #

    if(ARG_ENABLE_SANITIZER_ADDRESS)
        list(APPEND LIST_OF_SANITIZERS "address")
    endif()

    if(ARG_ENABLE_SANITIZER_LEAK)
        if("${CURRENT_COMPILER}" STREQUAL "MSVC")
            message(WARNING "Leak sanitizer is not supported on MSVC")
        else()
            list(APPEND LIST_OF_SANITIZERS "leak")
        endif()
    endif()

    if(ARG_ENABLE_SANITIZER_UNDEFINED_BEHAVIOR)
        if("${CURRENT_COMPILER}" STREQUAL "MSVC")
            message(WARNING "Undefined behavior sanitizer is not supported on MSVC")
        else()
            list(APPEND LIST_OF_SANITIZERS "undefined")
        endif()
    endif()

    if(ARG_ENABLE_SANITIZER_THREAD)
        if("${CURRENT_COMPILER}" STREQUAL "MSVC")
            message(WARNING "Thread sanitizer is not supported on MSVC")
        else()
            list(APPEND LIST_OF_SANITIZERS "thread")
        endif()
    endif()

    if(ARG_ENABLE_SANITIZER_MEMORY)
        if("${CURRENT_COMPILER}" STREQUAL "MSVC")
            message(WARNING "Memory sanitizer is not supported on MSVC")
        elseif("${CURRENT_COMPILER}" STREQUAL "Clang")
            message(WARNING
                "Memory sanitizer requires all the code (including libc++) to be MSan-instrumented otherwise it reports false positives"
            )

            if(${ARG_ENABLE_SANITIZER_ADDRESS} OR ${ARG_ENABLE_SANITIZER_THREAD} OR ${ARG_ENABLE_SANITIZER_LEAK})
                message(WARNING "Memory sanitizer does not work with Address, Thread or Leak sanitizer enabled")
            else()
                list(APPEND LIST_OF_SANITIZERS "memory")
            endif()
        endif()
    endif()

    # if LIST_OF_SANITIZERS is empty
    if(NOT LIST_OF_SANITIZERS)
        message(WARNING "No sanitizers enabled")
        return()
    endif()

    message(STATUS "Sanitizers enabled: ${LIST_OF_SANITIZERS} for ${TARGET_NAME}")

    # MSVC sanitizers
    if("${CURRENT_COMPILER}" STREQUAL "MSVC")
        # Check MSVC version - /fsanitize is only available in VS 2019 16.9+ and VS 2022
        if(MSVC_VERSION GREATER_EQUAL 1928)  # VS 2019 16.9+
            # Split sanitizer flags properly for MSVC
            foreach(sanitizer ${LIST_OF_SANITIZERS})
                target_compile_options(${TARGET_NAME} ${SCOPE_NAME} "/fsanitize=${sanitizer}")
            endforeach()
            # Always add debug info when using sanitizers to avoid C5072 warning
            target_compile_options(${TARGET_NAME} ${SCOPE_NAME} "/Zi")
            target_link_options(${TARGET_NAME} ${SCOPE_NAME} "/INCREMENTAL:NO")
            # Disable the ASAN warning about missing debug info since we're adding it
            target_compile_options(${TARGET_NAME} ${SCOPE_NAME} "/wd5072")
        else()
            message(WARNING "AddressSanitizer requires Visual Studio 2019 16.9 or later. Current MSVC version: ${MSVC_VERSION}")
            message(STATUS "Disabling sanitizers for ${TARGET_NAME} due to unsupported MSVC version")
            return()
        endif()

    elseif("${CURRENT_COMPILER}" MATCHES "Clang.*|GCC")
        # GCC/Clang sanitizers
        string(REPLACE ";" "," SANITIZER_FLAGS "${LIST_OF_SANITIZERS}")
        set(SANITIZER_FLAGS "-fsanitize=${SANITIZER_FLAGS}")
        target_compile_options(${TARGET_NAME} ${SCOPE_NAME} ${SANITIZER_FLAGS})
        target_link_options(${TARGET_NAME} ${SCOPE_NAME} ${SANITIZER_FLAGS})
    endif()

    if(${CURRENT_COMPILER} STREQUAL "MSVC")
        string(FIND "$ENV{PATH}" "$ENV{VSINSTALLDIR}" INDEX_OF_VS_INSTALL_DIR)
        if("${INDEX_OF_VS_INSTALL_DIR}" STREQUAL "-1")
            message(SEND_ERROR
                "Using MSVC sanitizers requires setting the MSVC environment before building the project. Please manually open the MSVC command prompt and rebuild the project."
            )
        endif()

        target_compile_definitions(${TARGET_NAME} ${SCOPE_NAME} _DISABLE_VECTOR_ANNOTATION _DISABLE_STRING_ANNOTATION)
        target_link_options(${TARGET_NAME} ${SCOPE_NAME} /INCREMENTAL:NO)
    else()
        target_link_options(${TARGET_NAME} ${SCOPE_NAME} ${SANITIZER_FLAGS})
    endif()
endfunction()

#
# Enable sanitizers globally for all targets and dependencies
#
function(enable_global_sanitizers)
    include(GetCurrentCompiler)
    get_current_compiler(CURRENT_COMPILER)

    # Sanitizers are primarily debugging tools and work best in Debug builds
    if(CMAKE_BUILD_TYPE STREQUAL "Release")
        message(STATUS "Disabling global sanitizers in Release mode (use Debug or RelWithDebInfo for sanitizers)")
        return()
    endif()

    set(LIST_OF_SANITIZERS "")

    if(ENABLE_ASAN)
        list(APPEND LIST_OF_SANITIZERS "address")
    endif()

    if(ENABLE_LSAN)
        if("${CURRENT_COMPILER}" STREQUAL "MSVC")
            message(WARNING "Leak sanitizer is not supported on MSVC")
        else()
            list(APPEND LIST_OF_SANITIZERS "leak")
        endif()
    endif()

    if(ENABLE_UBSAN)
        if("${CURRENT_COMPILER}" STREQUAL "MSVC")
            message(WARNING "Undefined behavior sanitizer is not supported on MSVC")
        else()
            list(APPEND LIST_OF_SANITIZERS "undefined")
        endif()
    endif()

    if(ENABLE_TSAN)
        if("${CURRENT_COMPILER}" STREQUAL "MSVC")
            message(WARNING "Thread sanitizer is not supported on MSVC")
        else()
            list(APPEND LIST_OF_SANITIZERS "thread")
        endif()
    endif()

    if(ENABLE_MSAN)
        if("${CURRENT_COMPILER}" STREQUAL "MSVC")
            message(WARNING "Memory sanitizer is not supported on MSVC")
        elseif("${CURRENT_COMPILER}" STREQUAL "Clang")
            message(WARNING
                "Memory sanitizer requires all the code (including libc++) to be MSan-instrumented otherwise it reports false positives"
            )

            if(${ENABLE_ASAN} OR ${ENABLE_TSAN} OR ${ENABLE_LSAN})
                message(WARNING "Memory sanitizer does not work with Address, Thread or Leak sanitizer enabled")
            else()
                list(APPEND LIST_OF_SANITIZERS "memory")
            endif()
        endif()
    endif()

    # if LIST_OF_SANITIZERS is empty
    if(NOT LIST_OF_SANITIZERS)
        message(STATUS "No global sanitizers to enable")
        return()
    endif()

    message(STATUS "** Enabling global sanitizers: ${LIST_OF_SANITIZERS}")

    # MSVC sanitizers
    if("${CURRENT_COMPILER}" STREQUAL "MSVC")
        # Check MSVC version - /fsanitize is only available in VS 2019 16.9+ and VS 2022
        if(MSVC_VERSION GREATER_EQUAL 1928)  # VS 2019 16.9+
            # Apply sanitizer flags globally
            foreach(sanitizer ${LIST_OF_SANITIZERS})
                set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /fsanitize=${sanitizer}" CACHE STRING "Global CXX flags with sanitizers" FORCE)
                set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /fsanitize=${sanitizer}" CACHE STRING "Global C flags with sanitizers" FORCE)
            endforeach()
            
            # Disable incremental linking when sanitizers are enabled to avoid LNK4300 warning
            # Sanitizers are incompatible with incremental linking
            set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /INCREMENTAL:NO" CACHE STRING "Global linker flags for executables with sanitizers" FORCE)
            set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} /INCREMENTAL:NO" CACHE STRING "Global linker flags for shared libraries with sanitizers" FORCE)
            set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} /INCREMENTAL:NO" CACHE STRING "Global linker flags for modules with sanitizers" FORCE)
            
            # Also disable incremental linking in MSBuild by setting property globally
            add_link_options(/INCREMENTAL:NO)
            
            # Find and copy AddressSanitizer runtime DLL to avoid missing DLL errors
            if("address" IN_LIST LIST_OF_SANITIZERS)
                # Determine architecture-specific DLL name
                if(CMAKE_SIZEOF_VOID_P EQUAL 8)
                    set(ASAN_DLL_PATTERN "clang_rt.asan_dynamic-x86_64.dll")
                    set(ARCH_DIR "x64")
                else()
                    set(ASAN_DLL_PATTERN "clang_rt.asan_dynamic-i386.dll")
                    set(ARCH_DIR "x86")
                endif()
                
                set(ASAN_RUNTIME_DLL "")
                
                # First, try to use vswhere to find Visual Studio installations
                find_program(VSWHERE_EXECUTABLE
                    NAMES vswhere.exe
                    PATHS 
                        "$ENV{ProgramFiles\(x86\)}/Microsoft Visual Studio/Installer"
                        "$ENV{ProgramFiles}/Microsoft Visual Studio/Installer"
                    DOC "Visual Studio locator tool"
                )
                
                if(VSWHERE_EXECUTABLE)
                    # Get Visual Studio installation path using vswhere
                    execute_process(
                        COMMAND "${VSWHERE_EXECUTABLE}" -latest -property installationPath
                        OUTPUT_VARIABLE VS_INSTALL_PATH
                        OUTPUT_STRIP_TRAILING_WHITESPACE
                        ERROR_QUIET
                    )
                    
                    if(VS_INSTALL_PATH AND EXISTS "${VS_INSTALL_PATH}")
                        # Search for AddressSanitizer runtime DLL in VC tools
                        file(GLOB_RECURSE ASAN_DLL_CANDIDATES 
                            "${VS_INSTALL_PATH}/VC/Tools/MSVC/*/bin/Host*/${ARCH_DIR}/${ASAN_DLL_PATTERN}")
                        
                        if(ASAN_DLL_CANDIDATES)
                            # Prefer the newest version (last in sorted list)
                            list(SORT ASAN_DLL_CANDIDATES)
                            list(GET ASAN_DLL_CANDIDATES -1 ASAN_RUNTIME_DLL)
                        endif()
                    endif()
                endif()
                
                # Fallback: Search in environment variables
                if(NOT ASAN_RUNTIME_DLL OR NOT EXISTS "${ASAN_RUNTIME_DLL}")
                    # Try VCToolsInstallDir environment variable
                    if(DEFINED ENV{VCToolsInstallDir})
                        file(GLOB_RECURSE ASAN_DLL_CANDIDATES 
                            "$ENV{VCToolsInstallDir}/bin/Host*/${ARCH_DIR}/${ASAN_DLL_PATTERN}")
                        if(ASAN_DLL_CANDIDATES)
                            list(SORT ASAN_DLL_CANDIDATES)
                            list(GET ASAN_DLL_CANDIDATES -1 ASAN_RUNTIME_DLL)
                        endif()
                    endif()
                    
                    # Try VCINSTALLDIR environment variable
                    if((NOT ASAN_RUNTIME_DLL OR NOT EXISTS "${ASAN_RUNTIME_DLL}") AND DEFINED ENV{VCINSTALLDIR})
                        file(GLOB_RECURSE ASAN_DLL_CANDIDATES 
                            "$ENV{VCINSTALLDIR}/Tools/MSVC/*/bin/Host*/${ARCH_DIR}/${ASAN_DLL_PATTERN}")
                        if(ASAN_DLL_CANDIDATES)
                            list(SORT ASAN_DLL_CANDIDATES)
                            list(GET ASAN_DLL_CANDIDATES -1 ASAN_RUNTIME_DLL)
                        endif()
                    endif()
                endif()
                
                if(ASAN_RUNTIME_DLL AND EXISTS "${ASAN_RUNTIME_DLL}")
                    message(STATUS "** Found AddressSanitizer runtime DLL at: ${ASAN_RUNTIME_DLL}")
                    # Set a global property so we can copy the DLL for each executable
                    set_property(GLOBAL PROPERTY ASAN_RUNTIME_DLL_PATH "${ASAN_RUNTIME_DLL}")
                else()
                    message(WARNING "AddressSanitizer runtime DLL (${ASAN_DLL_PATTERN}) not found. You may need to add the Visual Studio bin directory to your PATH.")
                    message(STATUS "** Searched architecture: ${ARCH_DIR}")
                    if(VSWHERE_EXECUTABLE)
                        message(STATUS "** Used vswhere: ${VSWHERE_EXECUTABLE}")
                    else()
                        message(STATUS "** vswhere not found, used fallback search")
                    endif()
                endif()
            endif()
            
            # Always add debug info when using sanitizers to avoid C5072 warning
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /Zi" CACHE STRING "Global CXX flags with debug info" FORCE)
            set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /Zi" CACHE STRING "Global C flags with debug info" FORCE)
            
            # Disable the ASAN warning about missing debug info since we're adding it
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /wd5072" CACHE STRING "Global CXX flags to disable ASAN warning" FORCE)
            set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /wd5072" CACHE STRING "Global C flags to disable ASAN warning" FORCE)
        else()
            message(WARNING "AddressSanitizer requires Visual Studio 2019 16.9 or later. Current MSVC version: ${MSVC_VERSION}")
            message(STATUS "Disabling global sanitizers due to unsupported MSVC version")
            return()
        endif()

    elseif("${CURRENT_COMPILER}" MATCHES "Clang.*|GCC")
        # GCC/Clang sanitizers
        string(REPLACE ";" "," SANITIZER_FLAGS "${LIST_OF_SANITIZERS}")
        set(SANITIZER_FLAGS "-fsanitize=${SANITIZER_FLAGS}")
        
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${SANITIZER_FLAGS}" CACHE STRING "Global CXX flags with sanitizers" FORCE)
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${SANITIZER_FLAGS}" CACHE STRING "Global C flags with sanitizers" FORCE)
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${SANITIZER_FLAGS}" CACHE STRING "Global EXE linker flags with sanitizers" FORCE)
        set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${SANITIZER_FLAGS}" CACHE STRING "Global SHARED linker flags with sanitizers" FORCE)
    endif()
endfunction()
