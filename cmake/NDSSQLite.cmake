# NDSSQLite.cmake - NDS SQLite DevKit backend implementation

include(FetchContent)

function(_add_nds_sqlite)
    # Variables from parent scope are already set with SQLITE_ prefix
    
    # Set NDS backend specific defaults
    if(NOT DEFINED SQLITE_NDS_TAG)
        set(SQLITE_NDS_TAG "SQLite-3.47.0")
    endif()
    
    if(NOT DEFINED SQLITE_ENABLE_COMPRESSION)
        set(SQLITE_ENABLE_COMPRESSION ON)
    endif()
    
    if(NOT DEFINED SQLITE_NDS_WITH_ICU)
        set(SQLITE_NDS_WITH_ICU OFF)
    endif()
    
    # Default features to ON (matching public backend)
    foreach(feature IN ITEMS ENABLE_FTS5 ENABLE_RTREE ENABLE_JSON1 ENABLE_MATH 
                            ENABLE_COLUMN_METADATA)
        if(NOT DEFINED SQLITE_${feature})
            set(SQLITE_${feature} ON)
        endif()
    endforeach()
    
    message(STATUS "Building with NDS SQLite DevKit")
    
    # Add C99 compatibility flags for macOS
    if(APPLE)
        add_compile_options(-Wno-deprecated-non-prototype -Wno-implicit-function-declaration)
    endif()
    
    # SQLite DevKit options - must be set BEFORE declaring the content
    set(NDS_SQLITE3_WITH_COLLATIONS_ICU ${SQLITE_NDS_WITH_ICU} CACHE BOOL 
        "Include all ICU collations (need icu library)" FORCE)
    set(NDS_SQLITE3_WITH_ANALYZER OFF CACHE BOOL 
        "Build SQLite analyzer (needs tcl library)" FORCE)
    set(NDS_SQLITE3_WITH_UNITTESTS OFF CACHE BOOL 
        "Build extensions unittests" FORCE)
    set(NDS_SQLITE3_WITH_SHELL OFF CACHE BOOL 
        "Build SQLite shell" FORCE)
    set(NDS_SQLITE3_WITH_TOOLS OFF CACHE BOOL 
        "Build SQLite tools (dbhash, rbu, sqldiff)" FORCE)
    set(NDS_SQLITE3_WITH_COMPRESSION ${SQLITE_ENABLE_COMPRESSION} CACHE BOOL 
        "Include NDS compression and encryption" FORCE)
    
    # Configure features based on user options
    if(SQLITE_ENABLE_FTS5)
        set(NDS_SQLITE3_ENABLE_FTS5 ON CACHE BOOL "" FORCE)
    endif()
    
    if(SQLITE_ENABLE_RTREE)
        set(NDS_SQLITE3_ENABLE_RTREE ON CACHE BOOL "" FORCE)
    endif()
    
    if(SQLITE_ENABLE_JSON1)
        set(NDS_SQLITE3_ENABLE_JSON1 ON CACHE BOOL "" FORCE)
    endif()
    
    if(SQLITE_ENABLE_COLUMN_METADATA)
        set(NDS_SQLITE3_ENABLE_COLUMN_METADATA ON CACHE BOOL "" FORCE)
    endif()
    
    # Declare NDS SQLite
    FetchContent_Declare(
        nds_sqlite_devkit
        GIT_REPOSITORY "${SQLITE_NDS_REPOSITORY_URL}"
        GIT_TAG        "${SQLITE_NDS_TAG}"
        GIT_SHALLOW    ON
    )
    
    # Set policy for old CMake minimum version
    set(CMAKE_POLICY_DEFAULT_CMP0048 NEW)
    set(CMAKE_POLICY_DEFAULT_CMP0077 NEW)
    
    # Get the source
    FetchContent_GetProperties(nds_sqlite_devkit)
    if(NOT nds_sqlite_devkit_POPULATED)
        message(STATUS "Fetching NDS SQLite DevKit (${SQLITE_NDS_TAG})")
        FetchContent_MakeAvailable(nds_sqlite_devkit)
    endif()
    
    if(NOT nds_sqlite_devkit_POPULATED)
        message(FATAL_ERROR "Failed to fetch SQLite DevKit. Note: this is only available to NDS members.")
    endif()
    
    # Workaround for macOS: Fix fdopen macro conflict in DevKit's zlib
    if(APPLE AND EXISTS "${nds_sqlite_devkit_SOURCE_DIR}/src/cpp/zlib/zutil.h")
        file(READ "${nds_sqlite_devkit_SOURCE_DIR}/src/cpp/zlib/zutil.h" ZUTIL_CONTENT)
        string(REPLACE "#        define fdopen(fd,mode) NULL /* No fdopen() */" 
                       "/* fdopen macro removed for macOS compatibility */" 
                       ZUTIL_CONTENT "${ZUTIL_CONTENT}")
        file(WRITE "${nds_sqlite_devkit_SOURCE_DIR}/src/cpp/zlib/zutil.h" "${ZUTIL_CONTENT}")
    endif()
    
    # Add the SQLite DevKit with policy context
    cmake_policy(PUSH)
    cmake_policy(SET CMP0048 NEW)
    if(POLICY CMP0077)
        cmake_policy(SET CMP0077 NEW)
    endif()
    add_subdirectory(${nds_sqlite_devkit_SOURCE_DIR}/src/cpp 
                     ${nds_sqlite_devkit_BINARY_DIR}
                     EXCLUDE_FROM_ALL)
    cmake_policy(POP)
    
    # Create compatibility layer
    _create_nds_compatibility_layer()
    
    # Create the public interface target with the requested name
    add_library(${SQLITE_TARGET_NAME} INTERFACE)
    
    # Link to the NDS SQLite target
    if(TARGET nds_sqlite3)
        target_link_libraries(${SQLITE_TARGET_NAME} INTERFACE nds_sqlite3)
        
        # Add include directories for compatibility headers
        target_include_directories(${SQLITE_TARGET_NAME} INTERFACE
            $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/sqlite_compat_includes>
            $<BUILD_INTERFACE:${nds_sqlite_devkit_SOURCE_DIR}/src/cpp/devkit>
        )
        
        # Add compile definition to indicate NDS backend
        target_compile_definitions(${SQLITE_TARGET_NAME} INTERFACE
            SQLITE_USING_NDS_BACKEND=1
        )
    else()
        message(FATAL_ERROR "Failed to find nds_sqlite3 target in DevKit")
    endif()
    
    # Create alias target if namespace is provided
    if(SQLITE_NAMESPACE)
        add_library(${SQLITE_NAMESPACE}::${SQLITE_TARGET_NAME} ALIAS ${SQLITE_TARGET_NAME})
    endif()
    
    # Make compression libraries available if enabled
    if(SQLITE_ENABLE_COMPRESSION)
        # Note: DevKit provides compression libraries as OBJECT libraries:
        # zlib_lib, zstd_lib, lz4_lib, brotli_lib
        # These are linked into nds_sqlite3 and available for use
        message(STATUS "  Compression libraries included: zlib, zstd, lz4, brotli")
    endif()
    
    # Note: The original nds_sqlite3 target remains available for backward compatibility
    # Apps can use either:
    #   - SQLite::SQLite3 (unified interface)
    #   - nds_sqlite3 (original NDS target)
    
    # Print configuration summary
    message(STATUS "  Git Tag: ${SQLITE_NDS_TAG}")
    message(STATUS "  Features:")
    message(STATUS "    FTS5: ${SQLITE_ENABLE_FTS5}")
    message(STATUS "    RTree: ${SQLITE_ENABLE_RTREE}")
    message(STATUS "    JSON1: ${SQLITE_ENABLE_JSON1}")
    message(STATUS "    Math: ${SQLITE_ENABLE_MATH}")
    message(STATUS "    Column Metadata: ${SQLITE_ENABLE_COLUMN_METADATA}")
    message(STATUS "    Compression: ${SQLITE_ENABLE_COMPRESSION}")
    message(STATUS "    ICU Collations: ${SQLITE_NDS_WITH_ICU}")
    message(STATUS "    Thread Safety: ${SQLITE_THREADSAFE}")
endfunction()

# Helper function to create compatibility headers
function(_create_nds_compatibility_layer)
    # Create a directory for compatibility headers
    set(COMPAT_INCLUDE_DIR "${CMAKE_BINARY_DIR}/sqlite_compat_includes")
    file(MAKE_DIRECTORY ${COMPAT_INCLUDE_DIR})
    
    # Create sqlite3.h wrapper that includes nds_sqlite3.h
    file(WRITE "${COMPAT_INCLUDE_DIR}/sqlite3.h" 
"/* Compatibility header for NDS SQLite DevKit */
#ifndef SQLITE3_COMPAT_H
#define SQLITE3_COMPAT_H

/* Include the actual NDS SQLite header */
#include \"nds_sqlite3.h\"

/* Map standard SQLite names to NDS variants if needed */
/* The NDS DevKit uses the same API, just different header names */

#endif /* SQLITE3_COMPAT_H */
")
    
    # Create sqlite3ext.h wrapper
    file(WRITE "${COMPAT_INCLUDE_DIR}/sqlite3ext.h" 
"/* Compatibility header for NDS SQLite DevKit extensions */
#ifndef SQLITE3EXT_COMPAT_H
#define SQLITE3EXT_COMPAT_H

/* Include the actual NDS SQLite extension header */
#include \"nds_sqlite3ext.h\"

#endif /* SQLITE3EXT_COMPAT_H */
")
    
    message(STATUS "  Created compatibility headers in: ${COMPAT_INCLUDE_DIR}")
endfunction()