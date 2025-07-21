include(CMakePackageConfigHelpers)

# Function to install shared library dependencies cross-platform
function(install_shared_library_dependencies target runtime_dir)
    # Get target type
    get_target_property(target_type ${target} TYPE)
    if(NOT target_type STREQUAL "EXECUTABLE" AND NOT target_type STREQUAL "SHARED_LIBRARY")
        return()  # Only handle executables and shared libraries
    endif()
    
    # Get target output name
    get_target_property(target_output_name ${target} OUTPUT_NAME)
    if(NOT target_output_name)
        set(target_output_name ${target})
    endif()
    
    # Create a post-install script to copy shared library dependencies
    set(install_script_file "${CMAKE_CURRENT_BINARY_DIR}/install_${target}_dependencies.cmake")
    
    file(WRITE ${install_script_file} "
# Auto-generated script to install shared library dependencies for ${target}
cmake_minimum_required(VERSION 3.15)

# Set policy for IN_LIST operator
if(POLICY CMP0057)
    cmake_policy(SET CMP0057 NEW)
endif()

# Get the target executable/library path - ensure it's absolute
get_filename_component(INSTALL_PREFIX_ABS \"\${CMAKE_INSTALL_PREFIX}\" ABSOLUTE)

# Platform-specific file extensions and library search patterns
if(WIN32)
    set(SHARED_LIB_EXTENSIONS \".dll\")
    set(EXECUTABLE_EXTENSION \".exe\")
elseif(APPLE)
    set(SHARED_LIB_EXTENSIONS \".dylib\" \".so\")
    set(EXECUTABLE_EXTENSION \"\")
else()
    set(SHARED_LIB_EXTENSIONS \".so\")
    set(EXECUTABLE_EXTENSION \"\")
endif()

# Determine target file based on type
if(\"${target_type}\" STREQUAL \"EXECUTABLE\")
    set(TARGET_FILE \"\${INSTALL_PREFIX_ABS}/${runtime_dir}/${target_output_name}\${EXECUTABLE_EXTENSION}\")
else()
    # For shared libraries, try different extensions
    foreach(ext \${SHARED_LIB_EXTENSIONS})
        set(potential_file \"\${INSTALL_PREFIX_ABS}/${runtime_dir}/${target_output_name}\${ext}\")
        if(EXISTS \"\${potential_file}\")
            set(TARGET_FILE \"\${potential_file}\")
            break()
        endif()
    endforeach()
endif()

if(EXISTS \"\${TARGET_FILE}\")
    message(STATUS \"Installing shared library dependencies for: \${TARGET_FILE}\")
    
    # Find all potential build directories where shared libraries might be located
    set(BUILD_DIR \"${CMAKE_BINARY_DIR}\")
    get_filename_component(TARGET_BUILD_BASE \"\${BUILD_DIR}\" ABSOLUTE)
    set(SEARCH_DIRECTORIES \"\")
    
    # Add common build output directory patterns
    foreach(config \"Release\" \"Debug\" \"RelWithDebInfo\" \"MinSizeRel\" \"\")
        foreach(subpath \"${CMAKE_CURRENT_BINARY_DIR}\" \"yuripp/discord-bot\" \".\")
            if(NOT \"\${config}\" STREQUAL \"\")
                set(potential_dir \"\${TARGET_BUILD_BASE}/\${subpath}/\${config}\")
            else()
                set(potential_dir \"\${TARGET_BUILD_BASE}/\${subpath}\")
            endif()
            if(EXISTS \"\${potential_dir}\")
                list(APPEND SEARCH_DIRECTORIES \"\${potential_dir}\")
            endif()
        endforeach()
    endforeach()
    
    # Search in CMake targets' output directories for transitive dependencies
    get_cmake_property(_target_names CACHE_VARIABLES)
    foreach(_cache_var \${_target_names})
        if(_cache_var MATCHES \".*_BINARY_DIR\$\")
            set(pkg_binary_dir \${${_cache_var}})
            if(EXISTS \"\${pkg_binary_dir}\")
                foreach(subdir \"Release\" \"Debug\" \"RelWithDebInfo\" \"MinSizeRel\" \"\" \"bin\" \"lib\" \"library\" \"dll\")
                    set(search_dir \"\${pkg_binary_dir}\")
                    if(NOT \"\${subdir}\" STREQUAL \"\")
                        set(search_dir \"\${pkg_binary_dir}/\${subdir}\")
                    endif()
                    if(EXISTS \"\${search_dir}\")
                        list(APPEND SEARCH_DIRECTORIES \"\${search_dir}\")
                    endif()
                endforeach()
            endif()
        endif()
    endforeach()
    
    # Also search in CPM package directories and their subdirectories
    get_cmake_property(_variableNames VARIABLES)
    foreach(_varName \${_variableNames})
        if(_varName MATCHES \".*_SOURCE_DIR\$\" OR _varName MATCHES \".*_BINARY_DIR\$\")
            set(pkg_dir \${${_varName}})
            if(EXISTS \"\${pkg_dir}\")
                # Search in common library subdirectories
                foreach(libsubdir \"\" \"bin\" \"lib\" \"library\" \"dll\" \"libs\" \"win32/lib\" \"win32/bin\" \"windows/lib\" \"windows/bin\")
                    foreach(configsubdir \"\" \"Release\" \"Debug\" \"RelWithDebInfo\" \"MinSizeRel\")
                        set(search_path \"\${pkg_dir}\")
                        if(NOT \"\${libsubdir}\" STREQUAL \"\")
                            set(search_path \"\${search_path}/\${libsubdir}\")
                        endif()
                        if(NOT \"\${configsubdir}\" STREQUAL \"\")
                            set(search_path \"\${search_path}/\${configsubdir}\")
                        endif()
                        if(EXISTS \"\${search_path}\")
                            list(APPEND SEARCH_DIRECTORIES \"\${search_path}\")
                        endif()
                    endforeach()
                endforeach()
            endif()
        endif()
    endforeach()
    
    # Remove duplicates and non-existent directories
    if(SEARCH_DIRECTORIES)
        list(REMOVE_DUPLICATES SEARCH_DIRECTORIES)
    endif()
    
    # Search for shared libraries in all directories
    set(COPIED_LIBRARIES \"\")
    foreach(search_dir \${SEARCH_DIRECTORIES})
        if(EXISTS \"\${search_dir}\")
            foreach(ext \${SHARED_LIB_EXTENSIONS})
                file(GLOB shared_libs \"\${search_dir}/*\${ext}\")
                foreach(lib_file \${shared_libs})
                    get_filename_component(lib_name \"\${lib_file}\" NAME)
                    set(dest_file \"\${INSTALL_PREFIX_ABS}/${runtime_dir}/\${lib_name}\")
                    
                    # Skip if it's the target itself
                    get_filename_component(target_basename \"\${TARGET_FILE}\" NAME)
                    if(NOT \"\${lib_name}\" STREQUAL \"\${target_basename}\" AND NOT \"\${lib_name}\" IN_LIST COPIED_LIBRARIES)
                        # Skip system libraries on Unix-like systems
                        set(skip_lib FALSE)
                        if(UNIX)
                            # Skip common system libraries
                            string(REGEX MATCH \"^lib(c|m|dl|pthread|rt|util|gcc_s|stdc\\\\+\\\\+)\\\\.so\" is_system_lib \"\${lib_name}\")
                            if(is_system_lib)
                                set(skip_lib TRUE)
                            endif()
                            # Skip libraries in system directories
                            string(FIND \"\${lib_file}\" \"/usr/lib\" usr_lib_pos)
                            string(FIND \"\${lib_file}\" \"/lib\" lib_pos)
                            if(usr_lib_pos GREATER_EQUAL 0 OR lib_pos EQUAL 0)
                                set(skip_lib TRUE)
                            endif()
                        elseif(WIN32)
                            # Skip Windows system DLLs
                            string(TOLOWER \"\${lib_file}\" lib_file_lower)
                            if(lib_file_lower MATCHES \"(system32|syswow64|winsxs|windows)\")
                                set(skip_lib TRUE)
                            endif()
                        endif()
                        
                        if(NOT skip_lib AND NOT EXISTS \"\${dest_file}\")
                            message(STATUS \"  Installing shared library dependency: \${lib_name}\")
                            execute_process(
                                COMMAND \"\${CMAKE_COMMAND}\" -E copy_if_different
                                \"\${lib_file}\"
                                \"\${dest_file}\"
                                RESULT_VARIABLE COPY_RESULT
                            )
                            if(NOT COPY_RESULT EQUAL 0)
                                message(WARNING \"Failed to copy \${lib_file} to \${dest_file}\")
                            else()
                                list(APPEND COPIED_LIBRARIES \"\${lib_name}\")
                            endif()
                        elseif(EXISTS \"\${dest_file}\")
                            message(STATUS \"  Shared library dependency already exists: \${lib_name}\")
                            list(APPEND COPIED_LIBRARIES \"\${lib_name}\")
                        elseif(skip_lib)
                            message(STATUS \"  Skipping system library: \${lib_name}\")
                        endif()
                    endif()
                endforeach()
            endforeach()
        endif()
    endforeach()
else()
    message(WARNING \"Target file does not exist: \${TARGET_FILE}\")
endif()
")

    # Install the script to run after the main installation
    install(SCRIPT ${install_script_file} COMPONENT Runtime)
    
    # Enhanced handling of target dependencies to include transitive dependencies
    get_target_property(target_link_libs ${target} LINK_LIBRARIES)
    if(target_link_libs)
        # Function to collect all dependency targets recursively (including static libraries with shared deps)
        function(collect_all_dependency_targets target_name visited_targets dependency_targets)
            # Avoid infinite recursion
            if(target_name IN_LIST visited_targets)
                return()
            endif()
            list(APPEND visited_targets ${target_name})
            
            if(TARGET ${target_name})
                get_target_property(target_type ${target_name} TYPE)
                
                list(APPEND dependency_targets ${target_name})
                
                # Recursively check this target's dependencies
                get_target_property(target_deps ${target_name} LINK_LIBRARIES)
                if(target_deps)
                    foreach(dep ${target_deps})
                        collect_all_dependency_targets(${dep} \"${visited_targets}\" dependency_targets)
                    endforeach()
                endif()
                
                # Also check interface link libraries for transitive dependencies
                get_target_property(interface_deps ${target_name} INTERFACE_LINK_LIBRARIES)
                if(interface_deps)
                    foreach(dep ${interface_deps})
                        if(TARGET ${dep})
                            collect_all_dependency_targets(${dep} \"${visited_targets}\" dependency_targets)
                        endif()
                    endforeach()
                endif()
            endif()
            
            # Propagate results back to parent scope
            set(dependency_targets ${dependency_targets} PARENT_SCOPE)
            set(visited_targets ${visited_targets} PARENT_SCOPE)
        endfunction()
        
        # Collect all dependency targets
        set(all_dependency_targets \"\")
        set(visited_list \"\")
        foreach(lib ${target_link_libs})
            collect_all_dependency_targets(${lib} \"${visited_list}\" all_dependency_targets)
        endforeach()
        
        # Remove duplicates
        if(all_dependency_targets)
            list(REMOVE_DUPLICATES all_dependency_targets)
        endif()
        
        # Install shared libraries for all dependency targets
        foreach(dep_target ${all_dependency_targets})
            if(TARGET ${dep_target})
                get_target_property(dep_type ${dep_target} TYPE)
                if(dep_type STREQUAL "SHARED_LIBRARY")
                    install(FILES $<TARGET_FILE:${dep_target}>
                        DESTINATION ${runtime_dir}
                        COMPONENT Runtime
                    )
                endif()
            endif()
        endforeach()
    endif()
endfunction()

#
# Helper function to install a target with specific components
# This function installs a target with the specified components and options.
# It handles the installation of runtime, library, and archive files,
# as well as public headers and export configuration.
# It also generates export headers for shared libraries.
#
# usage:
# install_component(target
#     [INCLUDE_SUBDIR <subdir>]
#     [NAMESPACE <namespace>]
#     [RUNTIME_DIR <runtime_dir>]
#     [LIBRARY_DIR <library_dir>]
#     [ARCHIVE_DIR <archive_dir>]
#     [EXPORT_MACRO_NAME <macro_name>]
#     [EXPORT_FILE_NAME <file_name>]
# )
#
# Arguments:
#   target: The target to install.
#   INCLUDE_SUBDIR: The subdirectory under the include directory where the public headers will be installed.
#   NAMESPACE: The namespace to use for the exported targets.
#   RUNTIME_DIR: The directory where runtime files (DLLs and executables) will be installed.
#   LIBRARY_DIR: The directory where library files (shared libraries) will be installed.
#   ARCHIVE_DIR: The directory where archive files (static/import libraries) will be installed.
#   EXPORT_MACRO_NAME: The name of the export define for the target.
#   EXPORT_FILE_NAME: The name of the export file to be generated.
#
# Example:
#   install_component(my_target
#       INCLUDE_SUBDIR "my_subdir"
#       NAMESPACE "my_namespace::"
#       RUNTIME_DIR "bin"
#       LIBRARY_DIR "lib"
#       ARCHIVE_DIR "lib"
#       EXPORT_MACRO_NAME "MYTARGET_EXPORT"
#       EXPORT_FILE_NAME "my_target_export.h"
#   )
#
function(install_component target)
    # Parse arguments
    set(oneValueArgs 
        INCLUDE_SUBDIR 
        NAMESPACE 
        RUNTIME_DIR 
        LIBRARY_DIR 
        ARCHIVE_DIR
        EXPORT_MACRO_NAME
        EXPORT_FILE_NAME
    )
    cmake_parse_arguments(ARG "" "${oneValueArgs}" "" ${ARGN})

    # Set defaults
    if (NOT ARG_INCLUDE_SUBDIR)
        set(ARG_INCLUDE_SUBDIR ${target})
    endif()
    if (NOT ARG_NAMESPACE)
        set(ARG_NAMESPACE ${THIS_PROJECT_NAMESPACE})
    endif()
    if (NOT ARG_RUNTIME_DIR)
        set(ARG_RUNTIME_DIR ${CMAKE_INSTALL_BINDIR})
    endif()
    if (NOT ARG_LIBRARY_DIR)
        set(ARG_LIBRARY_DIR ${CMAKE_INSTALL_LIBDIR})
    endif()
    if (NOT ARG_ARCHIVE_DIR)
        set(ARG_ARCHIVE_DIR ${CMAKE_INSTALL_LIBDIR})
    endif()
    if (NOT ARG_EXPORT_MACRO_NAME)
        set(ARG_EXPORT_MACRO_NAME "${target}_EXPORT")
    endif()
    if (NOT ARG_EXPORT_FILE_NAME)
        set(ARG_EXPORT_FILE_NAME "${ARG_INCLUDE_SUBDIR}/${target}_export.h")
    endif()

    # Get target type
    get_target_property(target_type ${target} TYPE)

    # Install target with appropriate components
    install(TARGETS ${target}
        EXPORT ${target}Targets
        RUNTIME DESTINATION ${ARG_RUNTIME_DIR}  # DLLs and executables
        LIBRARY DESTINATION ${ARG_RUNTIME_DIR}  # Shared libraries (same as executables)
        ARCHIVE DESTINATION ${ARG_ARCHIVE_DIR}  # Static/import libraries
        PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${ARG_INCLUDE_SUBDIR}
        INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    )
    
    # Install shared library dependencies for executables and shared libraries
    get_target_property(target_type ${target} TYPE)
    if(target_type STREQUAL "EXECUTABLE" OR target_type STREQUAL "SHARED_LIBRARY")
        install_shared_library_dependencies(${target} ${ARG_RUNTIME_DIR})
    endif()
    
    # Handle Emscripten WebAssembly files
    include(GetCurrentCompiler)
    get_current_compiler(CURRENT_COMPILER)
    if(CURRENT_COMPILER STREQUAL "EMSCRIPTEN")
        get_target_property(target_type ${target} TYPE)
        if(target_type STREQUAL "EXECUTABLE")
            # Install accompanying WASM files for Emscripten executables
            install(FILES 
                $<TARGET_FILE_DIR:${target}>/$<TARGET_FILE_BASE_NAME:${target}>.wasm
                DESTINATION ${ARG_RUNTIME_DIR}
                OPTIONAL
            )
        endif()
    endif()

    # Install export configuration
    install(EXPORT ${target}Targets
        FILE ${target}Config.cmake
        NAMESPACE ${ARG_NAMESPACE}
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${THIS_PROJECT_NAME}
    )

    # Handle shared library specifics
    if (${target_type} STREQUAL "SHARED_LIBRARY")
        # Generate export headers
        generate_export_header(${target}
            BASE_NAME ${target}
            EXPORT_MACRO_NAME ${ARG_EXPORT_MACRO_NAME}
            EXPORT_FILE_NAME "${CMAKE_CURRENT_BINARY_DIR}/include/${ARG_EXPORT_FILE_NAME}"
        )

        # Install export headers
        install(FILES 
            ${CMAKE_CURRENT_BINARY_DIR}/include/${ARG_EXPORT_FILE_NAME}
            DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${ARG_INCLUDE_SUBDIR}
        )
    endif()
endfunction()