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
    
    # Create internal target name to avoid conflicts
    set(INTERNAL_TARGET_NAME "_sqlite3_public_impl")
    
    # Prepare variables for the wrapper script
    set(_SQLITE_WRAPPER_CMAKE "${CMAKE_CURRENT_BINARY_DIR}/sqlite_wrapper.cmake")
    
    # Build the wrapper script content
    set(WRAPPER_CONTENT "# This script is executed after FetchContent downloads SQLite amalgamation\n")
    string(APPEND WRAPPER_CONTENT "# to create a CMakeLists.txt in the source directory\n\n")
    string(APPEND WRAPPER_CONTENT "if(NOT EXISTS \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\")\n")
    string(APPEND WRAPPER_CONTENT "    message(STATUS \"Creating CMakeLists.txt for SQLite amalgamation\")\n")
    string(APPEND WRAPPER_CONTENT "    \n")
    string(APPEND WRAPPER_CONTENT "    # Set variables\n")
    string(APPEND WRAPPER_CONTENT "    set(INTERNAL_TARGET_NAME \"${INTERNAL_TARGET_NAME}\")\n")
    string(APPEND WRAPPER_CONTENT "    set(SQLITE_LIB_TYPE \"${SQLITE_LIB_TYPE}\")\n")
    string(APPEND WRAPPER_CONTENT "    set(SQLITE_THREADSAFE \"${SQLITE_THREADSAFE}\")\n")
    string(APPEND WRAPPER_CONTENT "    set(SQLITE_ENABLE_FTS5 ${SQLITE_ENABLE_FTS5})\n")
    string(APPEND WRAPPER_CONTENT "    set(SQLITE_ENABLE_RTREE ${SQLITE_ENABLE_RTREE})\n")
    string(APPEND WRAPPER_CONTENT "    set(SQLITE_ENABLE_JSON1 ${SQLITE_ENABLE_JSON1})\n")
    string(APPEND WRAPPER_CONTENT "    set(SQLITE_ENABLE_MATH ${SQLITE_ENABLE_MATH})\n")
    string(APPEND WRAPPER_CONTENT "    set(SQLITE_ENABLE_COLUMN_METADATA ${SQLITE_ENABLE_COLUMN_METADATA})\n")
    string(APPEND WRAPPER_CONTENT "    \n")
    string(APPEND WRAPPER_CONTENT "    # Generate the CMakeLists.txt content\n")
    string(APPEND WRAPPER_CONTENT "    file(WRITE \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"")
    string(APPEND WRAPPER_CONTENT "cmake_minimum_required(VERSION 3.14)\\n")
    string(APPEND WRAPPER_CONTENT "project(sqlite3_public C)\\n\\n")
    string(APPEND WRAPPER_CONTENT "# Create SQLite library with internal name\\n")
    string(APPEND WRAPPER_CONTENT "add_library(\${INTERNAL_TARGET_NAME} \${SQLITE_LIB_TYPE} sqlite3.c)\\n\\n")
    string(APPEND WRAPPER_CONTENT "# Set include directories\\n")
    string(APPEND WRAPPER_CONTENT "target_include_directories(\${INTERNAL_TARGET_NAME} PUBLIC \\n")
    string(APPEND WRAPPER_CONTENT "    \\\$<BUILD_INTERFACE:\${CMAKE_CURRENT_SOURCE_DIR}>\\n")
    string(APPEND WRAPPER_CONTENT "    \\\$<INSTALL_INTERFACE:include>\\n")
    string(APPEND WRAPPER_CONTENT ")\\n\\n")
    string(APPEND WRAPPER_CONTENT "# Set compile definitions\\n")
    string(APPEND WRAPPER_CONTENT "target_compile_definitions(\${INTERNAL_TARGET_NAME} PRIVATE\\n")
    string(APPEND WRAPPER_CONTENT "    SQLITE_THREADSAFE=\${SQLITE_THREADSAFE}")
    string(APPEND WRAPPER_CONTENT "\")\n")
    string(APPEND WRAPPER_CONTENT "    \n")
    string(APPEND WRAPPER_CONTENT "    if(\${SQLITE_ENABLE_FTS5})\n")
    string(APPEND WRAPPER_CONTENT "        file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"\\n    SQLITE_ENABLE_FTS5=1\")\n")
    string(APPEND WRAPPER_CONTENT "    endif()\n")
    string(APPEND WRAPPER_CONTENT "    \n")
    string(APPEND WRAPPER_CONTENT "    if(\${SQLITE_ENABLE_RTREE})\n")
    string(APPEND WRAPPER_CONTENT "        file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"\\n    SQLITE_ENABLE_RTREE=1\")\n")
    string(APPEND WRAPPER_CONTENT "        file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"\\n    SQLITE_ENABLE_GEOPOLY=1\")\n")
    string(APPEND WRAPPER_CONTENT "    endif()\n")
    string(APPEND WRAPPER_CONTENT "    \n")
    string(APPEND WRAPPER_CONTENT "    if(\${SQLITE_ENABLE_JSON1})\n")
    string(APPEND WRAPPER_CONTENT "        file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"\\n    SQLITE_ENABLE_JSON1=1\")\n")
    string(APPEND WRAPPER_CONTENT "    endif()\n")
    string(APPEND WRAPPER_CONTENT "    \n")
    string(APPEND WRAPPER_CONTENT "    if(\${SQLITE_ENABLE_MATH})\n")
    string(APPEND WRAPPER_CONTENT "        file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"\\n    SQLITE_ENABLE_MATH_FUNCTIONS=1\")\n")
    string(APPEND WRAPPER_CONTENT "    endif()\n")
    string(APPEND WRAPPER_CONTENT "    \n")
    string(APPEND WRAPPER_CONTENT "    if(\${SQLITE_ENABLE_COLUMN_METADATA})\n")
    string(APPEND WRAPPER_CONTENT "        file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"\\n    SQLITE_ENABLE_COLUMN_METADATA=1\")\n")
    string(APPEND WRAPPER_CONTENT "    endif()\n")
    string(APPEND WRAPPER_CONTENT "    \n")
    string(APPEND WRAPPER_CONTENT "    # Add common useful defines\n")
    string(APPEND WRAPPER_CONTENT "    file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"\\n    SQLITE_DQS=0\")\n")
    string(APPEND WRAPPER_CONTENT "    file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"\\n    SQLITE_DEFAULT_MEMSTATUS=0\")\n")
    string(APPEND WRAPPER_CONTENT "    file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"\\n    SQLITE_DEFAULT_WAL_SYNCHRONOUS=1\")\n")
    string(APPEND WRAPPER_CONTENT "    file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"\\n    SQLITE_LIKE_DOESNT_MATCH_BLOBS\")\n")
    string(APPEND WRAPPER_CONTENT "    file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"\\n    SQLITE_MAX_EXPR_DEPTH=0\")\n")
    string(APPEND WRAPPER_CONTENT "    file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"\\n    SQLITE_OMIT_DEPRECATED\")\n")
    string(APPEND WRAPPER_CONTENT "    file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"\\n    SQLITE_OMIT_SHARED_CACHE\")\n")
    string(APPEND WRAPPER_CONTENT "    file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"\\n    SQLITE_USE_ALLOCA\")\n")
    string(APPEND WRAPPER_CONTENT "    file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"\\n)\\n\\n\")\n")
    string(APPEND WRAPPER_CONTENT "    file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"# Platform-specific settings\\n\")\n")
    string(APPEND WRAPPER_CONTENT "    file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"if(WIN32)\\n\")\n")
    string(APPEND WRAPPER_CONTENT "    file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"    target_compile_definitions(\${INTERNAL_TARGET_NAME} PRIVATE SQLITE_OS_WIN=1)\\n\")\n")
    string(APPEND WRAPPER_CONTENT "    file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"elseif(UNIX)\\n\")\n")
    string(APPEND WRAPPER_CONTENT "    file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"    target_compile_definitions(\${INTERNAL_TARGET_NAME} PRIVATE SQLITE_OS_UNIX=1)\\n\\n\")\n")
    string(APPEND WRAPPER_CONTENT "    file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"    # Check for and link required libraries\\n\")\n")
    string(APPEND WRAPPER_CONTENT "    file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"    include(CheckLibraryExists)\\n\\n\")\n")
    string(APPEND WRAPPER_CONTENT "    \n")
    string(APPEND WRAPPER_CONTENT "    if(\${SQLITE_ENABLE_MATH})\n")
    string(APPEND WRAPPER_CONTENT "        file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"    # Math library\\n\")\n")
    string(APPEND WRAPPER_CONTENT "        file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"    check_library_exists(m sqrt \\\"\\\" HAVE_LIB_M)\\n\")\n")
    string(APPEND WRAPPER_CONTENT "        file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"    if(HAVE_LIB_M)\\n\")\n")
    string(APPEND WRAPPER_CONTENT "        file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"        target_link_libraries(\${INTERNAL_TARGET_NAME} PUBLIC m)\\n\")\n")
    string(APPEND WRAPPER_CONTENT "        file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"    endif()\\n\\n\")\n")
    string(APPEND WRAPPER_CONTENT "    endif()\n")
    string(APPEND WRAPPER_CONTENT "    \n")
    string(APPEND WRAPPER_CONTENT "    file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"    # Dynamic loading library\\n\")\n")
    string(APPEND WRAPPER_CONTENT "    file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"    check_library_exists(dl dlopen \\\"\\\" HAVE_LIB_DL)\\n\")\n")
    string(APPEND WRAPPER_CONTENT "    file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"    if(HAVE_LIB_DL)\\n\")\n")
    string(APPEND WRAPPER_CONTENT "    file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"        target_link_libraries(\${INTERNAL_TARGET_NAME} PUBLIC dl)\\n\")\n")
    string(APPEND WRAPPER_CONTENT "    file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"    endif()\\n\")\n")
    string(APPEND WRAPPER_CONTENT "    file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"endif()\\n\\n\")\n")
    string(APPEND WRAPPER_CONTENT "    \n")
    string(APPEND WRAPPER_CONTENT "    if(\${SQLITE_THREADSAFE} GREATER 0)\n")
    string(APPEND WRAPPER_CONTENT "        file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"# Threading support\\n\")\n")
    string(APPEND WRAPPER_CONTENT "        file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"if(UNIX)\\n\")\n")
    string(APPEND WRAPPER_CONTENT "        file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"    find_package(Threads REQUIRED)\\n\")\n")
    string(APPEND WRAPPER_CONTENT "        file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"    target_link_libraries(\${INTERNAL_TARGET_NAME} PUBLIC Threads::Threads)\\n\")\n")
    string(APPEND WRAPPER_CONTENT "        file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"endif()\\n\\n\")\n")
    string(APPEND WRAPPER_CONTENT "    endif()\n")
    string(APPEND WRAPPER_CONTENT "    \n")
    string(APPEND WRAPPER_CONTENT "    file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"# Set properties\\n\")\n")
    string(APPEND WRAPPER_CONTENT "    file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"set_target_properties(\${INTERNAL_TARGET_NAME} PROPERTIES\\n\")\n")
    string(APPEND WRAPPER_CONTENT "    file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"    C_STANDARD 99\\n\")\n")
    string(APPEND WRAPPER_CONTENT "    file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"    C_STANDARD_REQUIRED ON\\n\")\n")
    string(APPEND WRAPPER_CONTENT "    file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"    POSITION_INDEPENDENT_CODE ON\\n\")\n")
    string(APPEND WRAPPER_CONTENT "    file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \"    OUTPUT_NAME sqlite3\\n\")\n")
    string(APPEND WRAPPER_CONTENT "    file(APPEND \"\${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt\" \")\\n\")\n")
    string(APPEND WRAPPER_CONTENT "endif()\n")
    
    # Write the wrapper script
    file(WRITE "${_SQLITE_WRAPPER_CMAKE}" "${WRAPPER_CONTENT}")
    
    # Declare SQLite with a hook to create CMakeLists.txt after download
    FetchContent_Declare(
        sqlite_public_amalgamation
        URL ${SQLITE_URL}
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    )
    
    # Set the include script that will be executed when the project is configured
    set(CMAKE_PROJECT_sqlite_public_amalgamation_INCLUDE "${_SQLITE_WRAPPER_CMAKE}")
    
    # Use MakeAvailable - it will download, create CMakeLists.txt via our hook, and add_subdirectory
    message(STATUS "Downloading SQLite ${SQLITE_VERSION} from ${SQLITE_URL}")
    FetchContent_MakeAvailable(sqlite_public_amalgamation)
    
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
