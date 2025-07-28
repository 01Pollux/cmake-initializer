# ==============================================================================
# Project Boilerplate - Modular CMake Functions
# ==============================================================================
# This file includes all modular components for the CMake project boilerplate
# system. Each module provides specific functionality for different target types.

# Include modular components
include(LinkDependencies)
include(InstallComponent)

include(boilerplate/RegisterExecutable)
include(boilerplate/RegisterLibrary)
include(boilerplate/RegisterEmscripten)
include(boilerplate/RegisterProject)
include(boilerplate/RegisterTest)
include(boilerplate/RegisterAssets)
