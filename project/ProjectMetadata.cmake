# Project name
set(THIS_PROJECT_NAME "cmake_initializer")
# Project pretty name
set(THIS_PROJECT_PRETTY_NAME "CMake Initializer Template")
# Project version
set(THIS_PROJECT_VERSION "1.0.0")
# Project namespace
set(THIS_PROJECT_NAMESPACE "cmake_initializer")
# Project description
set(THIS_PROJECT_DESCRIPTION "CMake Initializer Template")
# Project URL
if(NOT DEFINED THIS_PROJECT_HOMEPAGE_URL)
    set(THIS_PROJECT_HOMEPAGE_URL "https://github.com/01Pollux/cmake-initializer" CACHE STRING "Project homepage URL")
endif()
# Project license
set(THIS_PROJECT_LICENSE "MIT")

set(CMAKE_CXX_STANDARD "23")
