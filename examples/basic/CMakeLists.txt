cmake_minimum_required(VERSION 3.14)
project(sqlite_example LANGUAGES C CXX)

# Include the SQLite CMake module
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../../cmake)
include(SQLiteConfig)

# Option to choose backend
set(SQLITE_BACKEND "PUBLIC" CACHE STRING "SQLite backend to use (PUBLIC or NDS)")

# Option for NDS repository URL (only used when SQLITE_BACKEND=NDS)
set(SQLITE_NDS_REPOSITORY_URL "https://git.nds-association.org/NDS/sqlite-reference-engine.git" 
    CACHE STRING "Git repository URL for NDS SQLite DevKit")

# Configure SQLite based on the chosen backend
if(SQLITE_BACKEND STREQUAL "NDS")
    message(STATUS "Example: Using NDS SQLite backend")
    add_sqlite(
        BACKEND NDS
        NDS_REPOSITORY_URL "${SQLITE_NDS_REPOSITORY_URL}"
        NDS_TAG "SQLite-3.47.0"
        ENABLE_COMPRESSION ON
        ENABLE_FTS5 ON
        ENABLE_RTREE ON
        ENABLE_JSON1 ON
    )
else()
    message(STATUS "Example: Using public SQLite backend")
    add_sqlite(
        BACKEND PUBLIC
        VERSION 3.50.2
        ENABLE_FTS5 ON
        ENABLE_RTREE ON
        ENABLE_JSON1 ON
        ENABLE_MATH ON
    )
endif()

# Create example executable
add_executable(sqlite_example main.cpp)

# Link SQLite - same target name regardless of backend
target_link_libraries(sqlite_example PRIVATE SQLite::SQLite3)

# Set C++ standard
set_target_properties(sqlite_example PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED ON
)