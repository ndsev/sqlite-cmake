cmake_minimum_required(VERSION 3.14)
project(sqlite-cmake
        DESCRIPTION "Unified SQLite CMake integration module"
        LANGUAGES C CXX)

# Option to build examples
option(SQLITE_CMAKE_BUILD_EXAMPLES "Build SQLite CMake examples" ON)

# Make the cmake modules available
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

# Include SQLiteConfig to make add_sqlite available
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/SQLiteConfig.cmake)

# Also make the module path available to parent scope for includes
if(NOT CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
    set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} PARENT_SCOPE)
endif()

# Export the package for use from the build tree
export(PACKAGE SQLiteCMake)

# Create package config files
include(CMakePackageConfigHelpers)

# Generate the config file
configure_package_config_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/SQLiteConfig.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/SQLiteCMakeConfig.cmake
    INSTALL_DESTINATION lib/cmake/SQLiteCMake
    PATH_VARS CMAKE_INSTALL_PREFIX
)

# Generate the version file
write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/SQLiteCMakeConfigVersion.cmake
    VERSION 0.2.1
    COMPATIBILITY AnyNewerVersion
)

# Install the CMake modules
install(FILES
    cmake/SQLiteConfig.cmake
    cmake/PublicSQLite.cmake
    cmake/NDSSQLite.cmake
    DESTINATION lib/cmake/SQLiteCMake
)

# Install the generated config files
install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/SQLiteCMakeConfig.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/SQLiteCMakeConfigVersion.cmake
    DESTINATION lib/cmake/SQLiteCMake
)

# Build examples if requested
if(SQLITE_CMAKE_BUILD_EXAMPLES)
    add_subdirectory(examples/basic)
endif()
