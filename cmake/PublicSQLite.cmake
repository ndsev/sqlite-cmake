# PublicSQLite.cmake - Public SQLite backend implementation

include(FetchContent)

function(_add_public_sqlite)
    # Variables from parent scope are already set with SQLITE_ prefix
    
    # Set PUBLIC backend specific defaults
    if(NOT DEFINED SQLITE_VERSION)
        set(SQLITE_VERSION "3.50.2")
    endif()
    
    if(NOT DEFINED SQLITE_RELEASE_YEAR)
        set(SQLITE_RELEASE_YEAR "2025")
    endif()
    
    # Default features to ON
    foreach(feature IN ITEMS ENABLE_FTS5 ENABLE_RTREE ENABLE_JSON1 ENABLE_MATH 
                            ENABLE_COLUMN_METADATA)
        if(NOT DEFINED SQLITE_${feature})
            set(SQLITE_${feature} ON)
        endif()
    endforeach()
    
    # Set default thread safety if not specified
    if(NOT DEFINED SQLITE_THREADSAFE)
        set(SQLITE_THREADSAFE "1")
    endif()
    
    # Determine library type
    if(SQLITE_SHARED)
        set(SQLITE_LIB_TYPE SHARED)
    else()
        set(SQLITE_LIB_TYPE STATIC)
    endif()
    
    # Convert version to amalgamation format (3.46.1 -> 3460100)
    string(REPLACE "." ";" VERSION_LIST ${SQLITE_VERSION})
    list(GET VERSION_LIST 0 VERSION_MAJOR)
    list(GET VERSION_LIST 1 VERSION_MINOR)
    list(GET VERSION_LIST 2 VERSION_PATCH)
    math(EXPR AMALGAMATION_VERSION 
         "${VERSION_MAJOR} * 1000000 + ${VERSION_MINOR} * 10000 + ${VERSION_PATCH} * 100")
    
    # Download URL using the provided release year
    set(SQLITE_URL 
        "https://www.sqlite.org/${SQLITE_RELEASE_YEAR}/sqlite-amalgamation-${AMALGAMATION_VERSION}.zip")
    
    # Declare SQLite
    FetchContent_Declare(
        sqlite_public_amalgamation
        URL ${SQLITE_URL}
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    )
    
    # Get the source
    FetchContent_GetProperties(sqlite_public_amalgamation)
    if(NOT sqlite_public_amalgamation_POPULATED)
        message(STATUS "Downloading SQLite ${SQLITE_VERSION} from ${SQLITE_URL}")
        FetchContent_Populate(sqlite_public_amalgamation)
        
        # Create internal target name to avoid conflicts
        set(INTERNAL_TARGET_NAME "_sqlite3_public_impl")
        
        # Create a minimal CMakeLists.txt for SQLite
        set(SQLITE_CMAKE_CONTENT "
cmake_minimum_required(VERSION 3.14)
project(sqlite3_public C)

# Create SQLite library with internal name
add_library(${INTERNAL_TARGET_NAME} ${SQLITE_LIB_TYPE} sqlite3.c)

# Set include directories
target_include_directories(${INTERNAL_TARGET_NAME} PUBLIC 
    $<BUILD_INTERFACE:\${CMAKE_CURRENT_SOURCE_DIR}>
    $<INSTALL_INTERFACE:include>
)

# Set compile definitions
target_compile_definitions(${INTERNAL_TARGET_NAME} PRIVATE
    SQLITE_THREADSAFE=${SQLITE_THREADSAFE}")
        
        # Add optional features
        if(SQLITE_ENABLE_FTS5)
            string(APPEND SQLITE_CMAKE_CONTENT "    SQLITE_ENABLE_FTS5=1\n")
        endif()
        
        if(SQLITE_ENABLE_RTREE)
            string(APPEND SQLITE_CMAKE_CONTENT "    SQLITE_ENABLE_RTREE=1\n")
            string(APPEND SQLITE_CMAKE_CONTENT "    SQLITE_ENABLE_GEOPOLY=1\n")
        endif()
        
        if(SQLITE_ENABLE_JSON1)
            string(APPEND SQLITE_CMAKE_CONTENT "    SQLITE_ENABLE_JSON1=1\n")
        endif()
        
        if(SQLITE_ENABLE_MATH)
            string(APPEND SQLITE_CMAKE_CONTENT "    SQLITE_ENABLE_MATH_FUNCTIONS=1\n")
        endif()
        
        if(SQLITE_ENABLE_COLUMN_METADATA)
            string(APPEND SQLITE_CMAKE_CONTENT "    SQLITE_ENABLE_COLUMN_METADATA=1\n")
        endif()
        
        # Add common useful defines
        string(APPEND SQLITE_CMAKE_CONTENT "    SQLITE_DQS=0\n")
        string(APPEND SQLITE_CMAKE_CONTENT "    SQLITE_DEFAULT_MEMSTATUS=0\n")
        string(APPEND SQLITE_CMAKE_CONTENT "    SQLITE_DEFAULT_WAL_SYNCHRONOUS=1\n")
        string(APPEND SQLITE_CMAKE_CONTENT "    SQLITE_LIKE_DOESNT_MATCH_BLOBS\n")
        string(APPEND SQLITE_CMAKE_CONTENT "    SQLITE_MAX_EXPR_DEPTH=0\n")
        string(APPEND SQLITE_CMAKE_CONTENT "    SQLITE_OMIT_DEPRECATED\n")
        string(APPEND SQLITE_CMAKE_CONTENT "    SQLITE_OMIT_SHARED_CACHE\n")
        string(APPEND SQLITE_CMAKE_CONTENT "    SQLITE_USE_ALLOCA\n")
        
        string(APPEND SQLITE_CMAKE_CONTENT ")

# Platform-specific settings
if(WIN32)
    target_compile_definitions(${INTERNAL_TARGET_NAME} PRIVATE SQLITE_OS_WIN=1)
elseif(UNIX)
    target_compile_definitions(${INTERNAL_TARGET_NAME} PRIVATE SQLITE_OS_UNIX=1)
    
    # Check for and link required libraries
    include(CheckLibraryExists)
    
    # Math library
    if(${SQLITE_ENABLE_MATH})
        check_library_exists(m sqrt \"\" HAVE_LIB_M)
        if(HAVE_LIB_M)
            target_link_libraries(${INTERNAL_TARGET_NAME} PUBLIC m)
        endif()
    endif()
    
    # Dynamic loading library
    check_library_exists(dl dlopen \"\" HAVE_LIB_DL)
    if(HAVE_LIB_DL)
        target_link_libraries(${INTERNAL_TARGET_NAME} PUBLIC dl)
    endif()
    
    # Threading library
endif()
")
        
        # Add threading support if needed
        if(SQLITE_THREADSAFE GREATER 0)
            string(APPEND SQLITE_CMAKE_CONTENT "
# Threading support
if(UNIX)
    find_package(Threads REQUIRED)
    target_link_libraries(${INTERNAL_TARGET_NAME} PUBLIC Threads::Threads)
endif()
")
        endif()
        
        # Add properties section
        string(APPEND SQLITE_CMAKE_CONTENT "
# Set properties
set_target_properties(${INTERNAL_TARGET_NAME} PROPERTIES
    C_STANDARD 99
    C_STANDARD_REQUIRED ON
    POSITION_INDEPENDENT_CODE ON
    OUTPUT_NAME sqlite3
)
")
        
        # Write the CMakeLists.txt
        file(WRITE ${sqlite_public_amalgamation_SOURCE_DIR}/CMakeLists.txt 
             "${SQLITE_CMAKE_CONTENT}")
    endif()
    
    # Add the subdirectory
    add_subdirectory(${sqlite_public_amalgamation_SOURCE_DIR} 
                     ${sqlite_public_amalgamation_BINARY_DIR} 
                     EXCLUDE_FROM_ALL)
    
    # Create the public interface target with the requested name
    add_library(${SQLITE_TARGET_NAME} INTERFACE)
    target_link_libraries(${SQLITE_TARGET_NAME} INTERFACE ${INTERNAL_TARGET_NAME})
    
    # Create alias target if namespace is provided
    if(SQLITE_NAMESPACE)
        add_library(${SQLITE_NAMESPACE}::${SQLITE_TARGET_NAME} ALIAS ${SQLITE_TARGET_NAME})
    endif()
    
    # Print configuration summary
    message(STATUS "  Version: ${SQLITE_VERSION}")
    message(STATUS "  Type: ${SQLITE_LIB_TYPE}")
    message(STATUS "  Features:")
    message(STATUS "    FTS5: ${SQLITE_ENABLE_FTS5}")
    message(STATUS "    RTree: ${SQLITE_ENABLE_RTREE}")
    message(STATUS "    JSON1: ${SQLITE_ENABLE_JSON1}")
    message(STATUS "    Math: ${SQLITE_ENABLE_MATH}")
    message(STATUS "    Column Metadata: ${SQLITE_ENABLE_COLUMN_METADATA}")
    message(STATUS "    Thread Safety: ${SQLITE_THREADSAFE}")
endfunction()
