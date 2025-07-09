include(CheckSanitizerSupport)
include(CMakeDependentOption)

# Check what sanitizers are supported
check_sanitizers_support(SUPPORTS_UBSAN SUPPORTS_ASAN)

option(DEV_MODE "Enable development mode (all quality tools)" ON)
option(RELEASE_MODE "Enable release optimizations" OFF)

option(ENABLE_SANITIZERS "Enable address/undefined behavior sanitizers" ${DEV_MODE})
option(ENABLE_STATIC_ANALYSIS "Enable clang-tidy and cppcheck" ${DEV_MODE})
option(ENABLE_WARNINGS_AS_ERRORS "Treat warnings as errors" ${DEV_MODE})
option(ENABLE_IPO "Enable link-time optimization" ${RELEASE_MODE})
option(ENABLE_UNITY_BUILD "Enable unity builds for faster compilation" OFF)
option(ENABLE_PCH "Enable precompiled headers" OFF)

if(DEV_MODE OR ENABLE_SANITIZERS)
    set(DEFAULT_ASAN ${SUPPORTS_ASAN})
    set(DEFAULT_UBSAN ${SUPPORTS_UBSAN})
else()
    set(DEFAULT_ASAN OFF)
    set(DEFAULT_UBSAN OFF)
endif()

option(ENABLE_ASAN "Enable address sanitizer" ${DEFAULT_ASAN})
option(ENABLE_LSAN "Enable leak sanitizer" OFF)
option(ENABLE_UBSAN "Enable undefined behavior sanitizer" ${DEFAULT_UBSAN})
option(ENABLE_TSAN "Enable thread sanitizer" OFF)
option(ENABLE_MSAN "Enable memory sanitizer" OFF)
option(ENABLE_CLANG_TIDY "Enable clang-tidy" ${ENABLE_STATIC_ANALYSIS})
option(ENABLE_CPPCHECK "Enable cppcheck" ${ENABLE_STATIC_ANALYSIS})

#

mark_as_advanced(
    ENABLE_ASAN ENABLE_LSAN ENABLE_UBSAN ENABLE_TSAN ENABLE_MSAN
    ENABLE_CLANG_TIDY ENABLE_CPPCHECK
    ENABLE_UNITY_BUILD ENABLE_PCH
)

# Set up global hardening based on sanitizer settings
cmake_dependent_option(
    ENABLE_HARDENING
    "Enable security hardening options"
    ON "ENABLE_SANITIZERS OR DEV_MODE" OFF
)
