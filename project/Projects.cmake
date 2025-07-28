
# Enable testing
if(BUILD_TESTING)
    include(CTest)
    enable_testing()
endif()

add_subdirectory(base)
add_subdirectory(samples)
