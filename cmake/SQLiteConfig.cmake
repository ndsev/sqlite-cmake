# SQLiteConfig.cmake - Unified SQLite integration module
# Supports both public SQLite and NDS SQLite DevKit transparently

include(FetchContent)

# Store the directory containing this file for later use in functions
set(_SQLITE_CMAKE_DIR "${CMAKE_CURRENT_LIST_DIR}" CACHE INTERNAL "Directory containing SQLite CMake modules")

#[=======================================================================[.rst:
add_sqlite
----------

Integrates SQLite into your project with support for both public SQLite 
and NDS SQLite DevKit backends.

Synopsis
^^^^^^^^
.. code-block:: cmake

  add_sqlite(
    BACKEND <PUBLIC|NDS>
    [VERSION <version>]
    [RELEASE_YEAR <year>]
    [TARGET_NAME <name>]
    [NAMESPACE <namespace>]
    [ENABLE_FTS5 <ON|OFF>]
    [ENABLE_RTREE <ON|OFF>]
    [ENABLE_JSON1 <ON|OFF>]
    [ENABLE_MATH <ON|OFF>]
    [ENABLE_COLUMN_METADATA <ON|OFF>]
    [ENABLE_COMPRESSION <ON|OFF>]
    [THREADSAFE <0|1|2>]
    [SHARED]
    [NDS_TAG <git-tag>]
    [NDS_WITH_ICU <ON|OFF>]
  )

Options
^^^^^^^
``BACKEND``
  Required. Choose between PUBLIC (sqlite.org) or NDS (NDS DevKit)

``VERSION``
  SQLite version to download (default: 3.50.2) - PUBLIC backend only

``RELEASE_YEAR``
  Year of SQLite release for download URL (default: 2025) - PUBLIC backend only

``TARGET_NAME``
  Name of the created target (default: SQLite3)

``NAMESPACE``
  Namespace for alias target (default: SQLite)
  Creates ${NAMESPACE}::${TARGET_NAME} alias

``ENABLE_FTS5``
  Enable Full-Text Search 5 (default: ON)

``ENABLE_RTREE``
  Enable R*Tree index (default: ON)

``ENABLE_JSON1``
  Enable JSON1 extension (default: ON)

``ENABLE_MATH``
  Enable math functions (default: ON)

``ENABLE_COLUMN_METADATA``
  Enable column metadata functions (default: ON)

``ENABLE_COMPRESSION``
  Enable NDS compression and encryption (default: ON) - NDS backend only

``THREADSAFE``
  Thread-safety level: 0=single-threaded, 1=serialized, 2=multi-threaded (default: 1)

``SHARED``
  Build as shared library instead of static

``NDS_TAG``
  Git tag for NDS SQLite repository (default: SQLite-3.47.0) - NDS backend only

``NDS_WITH_ICU``
  Include ICU collations (default: OFF) - NDS backend only

Example
^^^^^^^
.. code-block:: cmake

  # Use public SQLite
  add_sqlite(
    BACKEND PUBLIC
    VERSION 3.50.2
    ENABLE_FTS5 ON
    ENABLE_RTREE ON
  )
  
  # Use NDS SQLite DevKit
  add_sqlite(
    BACKEND NDS
    NDS_TAG "SQLite-3.47.0"
    ENABLE_COMPRESSION ON
  )
  
  # Link the same way regardless of backend
  target_link_libraries(myapp PRIVATE SQLite::SQLite3)

#]=======================================================================]

function(add_sqlite)
    set(options SHARED ENABLE_FTS5 ENABLE_RTREE ENABLE_JSON1 ENABLE_MATH 
                ENABLE_COLUMN_METADATA ENABLE_COMPRESSION NDS_WITH_ICU)
    set(oneValueArgs BACKEND VERSION RELEASE_YEAR TARGET_NAME NAMESPACE 
                     THREADSAFE NDS_TAG NDS_REPOSITORY_URL)
    cmake_parse_arguments(SQLITE "${options}" "${oneValueArgs}" "" ${ARGN})
    
    # Validate required parameters
    if(NOT DEFINED SQLITE_BACKEND)
        message(FATAL_ERROR "add_sqlite: BACKEND parameter is required (PUBLIC or NDS)")
    endif()
    
    if(NOT SQLITE_BACKEND STREQUAL "PUBLIC" AND NOT SQLITE_BACKEND STREQUAL "NDS")
        message(FATAL_ERROR "add_sqlite: BACKEND must be either PUBLIC or NDS")
    endif()
    
    # Validate NDS backend requirements
    if(SQLITE_BACKEND STREQUAL "NDS" AND NOT DEFINED SQLITE_NDS_REPOSITORY_URL)
        message(FATAL_ERROR "add_sqlite: NDS_REPOSITORY_URL is required when using BACKEND NDS")
    endif()
    
    # Set defaults
    if(NOT DEFINED SQLITE_TARGET_NAME)
        set(SQLITE_TARGET_NAME "SQLite3")
    endif()
    
    if(NOT DEFINED SQLITE_NAMESPACE)
        set(SQLITE_NAMESPACE "SQLite")
    endif()
    
    if(NOT DEFINED SQLITE_THREADSAFE)
        set(SQLITE_THREADSAFE "1")
    endif()
    
    # Check if target already exists
    if(TARGET ${SQLITE_TARGET_NAME})
        message(STATUS "add_sqlite: Target '${SQLITE_TARGET_NAME}' already exists. Skipping.")
        return()
    endif()
    
    if(TARGET ${SQLITE_NAMESPACE}::${SQLITE_TARGET_NAME})
        message(STATUS "add_sqlite: Target '${SQLITE_NAMESPACE}::${SQLITE_TARGET_NAME}' already exists. Skipping.")
        return()
    endif()
    
    # Store the backend choice globally for other modules to access
    set(SQLITE_BACKEND_CHOICE "${SQLITE_BACKEND}" CACHE INTERNAL "Selected SQLite backend")
    
    # Dispatch to appropriate backend
    if(SQLITE_BACKEND STREQUAL "PUBLIC")
        message(STATUS "Configuring SQLite with PUBLIC backend")
        include(${_SQLITE_CMAKE_DIR}/PublicSQLite.cmake)
        _add_public_sqlite()
    else()
        message(STATUS "Configuring SQLite with NDS DevKit backend")
        include(${_SQLITE_CMAKE_DIR}/NDSSQLite.cmake)
        _add_nds_sqlite()
    endif()
    
    # Verify the target was created
    if(NOT TARGET ${SQLITE_NAMESPACE}::${SQLITE_TARGET_NAME})
        message(FATAL_ERROR "add_sqlite: Failed to create SQLite target")
    endif()
    
    # Set success flag in parent scope
    set(${SQLITE_TARGET_NAME}_FOUND TRUE PARENT_SCOPE)
    
    message(STATUS "SQLite configured successfully")
    message(STATUS "  Backend: ${SQLITE_BACKEND}")
    message(STATUS "  Target: ${SQLITE_TARGET_NAME}")
    message(STATUS "  Alias: ${SQLITE_NAMESPACE}::${SQLITE_TARGET_NAME}")
endfunction()