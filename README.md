# SQLite CMake

A unified CMake module for integrating SQLite into your projects with support for both public SQLite and NDS SQLite DevKit backends.

## Features

- **Dual Backend Support**: Seamlessly switch between public SQLite and NDS SQLite DevKit
- **Transparent Interface**: Use `SQLite::SQLite3` target regardless of backend
- **Feature Parity**: All standard SQLite features available in both backends
- **Easy Integration**: Simple CMake function call to add SQLite to your project
- **Platform Support**: Automatic handling of platform-specific requirements

## Requirements

- CMake 3.14 or higher
- C compiler with C99 support
- Git (for fetching dependencies)
- For NDS backend: Access to NDS SQLite repository (NDS members only)

## Quick Start

### Using FetchContent (Recommended)

```cmake
include(FetchContent)
FetchContent_Declare(
    sqlite_cmake
    GIT_REPOSITORY https://github.com/ndsev/sqlite-cmake.git
    GIT_TAG main
)
FetchContent_MakeAvailable(sqlite_cmake)

# Use public SQLite
add_sqlite(BACKEND PUBLIC VERSION 3.50.2)

# Or use NDS SQLite
add_sqlite(
    BACKEND NDS
    NDS_REPOSITORY_URL "https://your-private-git.com/path/to/nds-sqlite.git"
    NDS_TAG "SQLite-3.47.0"
)

# Link the same way regardless of backend
target_link_libraries(your_target PRIVATE SQLite::SQLite3)
```

### Local Installation

```bash
git clone https://github.com/your-org/sqlite-cmake.git  # Replace with actual repo URL
cd sqlite-cmake
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/path/to/install
cmake --install .
```

Then in your project:

```cmake
find_package(SQLiteCMake REQUIRED)
add_sqlite(BACKEND PUBLIC)
target_link_libraries(your_target PRIVATE SQLite::SQLite3)
```

## API Reference

### add_sqlite Function

```cmake
add_sqlite(
    BACKEND <PUBLIC|NDS>              # Required: Backend selection
    [VERSION <version>]               # SQLite version (PUBLIC only, default: 3.50.2)
    [RELEASE_YEAR <year>]            # Release year (PUBLIC only, default: 2025)
    [TARGET_NAME <name>]             # Target name (default: SQLite3)
    [NAMESPACE <namespace>]          # Namespace (default: SQLite)
    
    # Feature flags
    [ENABLE_FTS5 <ON|OFF>]          # Full-Text Search 5 (default: ON)
    [ENABLE_RTREE <ON|OFF>]         # R*Tree index (default: ON)
    [ENABLE_JSON1 <ON|OFF>]         # JSON1 extension (default: ON)
    [ENABLE_MATH <ON|OFF>]          # Math functions (default: ON)
    [ENABLE_COLUMN_METADATA <ON|OFF>] # Column metadata (default: ON)
    [ENABLE_COMPRESSION <ON|OFF>]    # Compression (NDS only, default: ON)
    
    # Build options
    [THREADSAFE <0|1|2>]            # Thread safety (default: 1)
    [SHARED]                        # Build as shared library
    
    # NDS-specific options
    [NDS_REPOSITORY_URL <url>]      # Git repository URL (required for NDS backend)
    [NDS_TAG <git-tag>]             # Git tag for NDS SQLite (default: SQLite-3.47.0)
    [NDS_WITH_ICU <ON|OFF>]         # ICU collations (default: OFF)
)
```

## Backend Comparison

| Feature | Public SQLite | NDS SQLite |
|---------|--------------|------------|
| Source | sqlite.org | NDS Git Repository |
| Compression | No | Yes (zlib, zstd, lz4, brotli) |
| Encryption | No | Yes |
| Standard Features | Yes | Yes |
| Header Files | sqlite3.h | nds_sqlite3.h (with compatibility) |
| License | Public Domain | NDS Members Only |
| Legacy Target | N/A | `nds_sqlite3` (still available) |

## Examples

### Basic Usage

```cpp
#include <sqlite3.h>
#include <iostream>

int main() {
    sqlite3* db;
    int rc = sqlite3_open(":memory:", &db);
    
    if (rc == SQLITE_OK) {
        std::cout << "SQLite version: " << sqlite3_libversion() << std::endl;
        sqlite3_close(db);
    }
    
    return 0;
}
```

### Switching Backends

```cmake
# Development: Use public SQLite
if(DEVELOPMENT_BUILD)
    add_sqlite(BACKEND PUBLIC VERSION 3.50.2)
# Production: Use NDS SQLite with compression
else()
    add_sqlite(
        BACKEND NDS
        NDS_REPOSITORY_URL "${NDS_SQLITE_REPO_URL}"  # Set via environment or CMake variable
        ENABLE_COMPRESSION ON
    )
endif()

# Code remains the same
target_link_libraries(app PRIVATE SQLite::SQLite3)
```

### Feature Detection

```cpp
#ifdef SQLITE_USING_NDS_BACKEND
    std::cout << "Using NDS SQLite with compression support" << std::endl;
#else
    std::cout << "Using public SQLite" << std::endl;
#endif
```

### Backward Compatibility (NDS Backend)

When using the NDS backend, the original `nds_sqlite3` target remains available:

```cmake
add_sqlite(
    BACKEND NDS
    NDS_REPOSITORY_URL "https://your-private-git.com/path/to/nds-sqlite.git"
)

# Both targets are available:
target_link_libraries(app1 PRIVATE SQLite::SQLite3)  # Unified interface
target_link_libraries(app2 PRIVATE nds_sqlite3)      # Legacy NDS target
```

## Advanced Usage

### Custom Target Names

```cmake
add_sqlite(
    BACKEND PUBLIC
    TARGET_NAME CustomSQLite
    NAMESPACE MyProject
)
target_link_libraries(app PRIVATE MyProject::CustomSQLite)
```

### Platform-Specific Configuration

The module automatically handles platform-specific requirements:
- **Linux/Unix**: Links with `m`, `dl`, and `pthread` as needed
- **Windows**: Sets `SQLITE_OS_WIN=1`
- **macOS**: Handles NDS DevKit zlib compatibility issues

### Building with Examples

```bash
mkdir build && cd build
cmake .. -DSQLITE_CMAKE_BUILD_EXAMPLES=ON
cmake --build .

# Run the example
./examples/basic/sqlite_example
```

## Troubleshooting

### NDS Backend Access Denied

If you get an error fetching the NDS SQLite repository, ensure:
1. You have valid NDS member credentials
2. Git is configured with proper authentication
3. You have access to `https://git.nds-association.org`

### Duplicate Target Errors

The module checks for existing targets. If you see warnings about existing targets:
1. Ensure you're not including SQLite from multiple sources
2. Call `add_sqlite()` only once in your project hierarchy

### Header Compatibility

When switching from public to NDS backend:
- The module provides compatibility headers
- No code changes needed
- `#include <sqlite3.h>` works with both backends

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This CMake module is provided under the MIT License. See LICENSE file for details.

Note: SQLite itself has its own licensing:
- Public SQLite: Public Domain
- NDS SQLite DevKit: NDS Member License
