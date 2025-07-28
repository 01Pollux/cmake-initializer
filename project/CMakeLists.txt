cmake_minimum_required(VERSION 3.21)

message(STATUS "CMake version: ${CMAKE_VERSION}")
message(STATUS "Using C++ standard: ${CMAKE_CXX_STANDARD}")

#

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)

#

include(PreventInSourceBuilds)
include(project/Initialization)
include(./ProjectMetadata.cmake)

# Set up project with metadata
project(${THIS_PROJECT_NAME}
    VERSION "${THIS_PROJECT_VERSION}"
    DESCRIPTION ${THIS_PROJECT_DESCRIPTION}
    LANGUAGES CXX
    HOMEPAGE_URL ${THIS_PROJECT_HOMEPAGE_URL}
)

message(STATUS "Configuring ${THIS_PROJECT_PRETTY_NAME} v${THIS_PROJECT_VERSION}")

include(Projects.cmake)
