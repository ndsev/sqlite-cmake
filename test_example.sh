#!/bin/bash

echo "Testing SQLite CMake Module - Public Backend"
echo "==========================================="

# Create build directory
mkdir -p build
cd build

# Configure with public backend
echo "Configuring with PUBLIC backend..."
cmake .. -DSQLITE_CMAKE_BUILD_EXAMPLES=ON

# Build
echo "Building example..."
cmake --build .

# Run the example
echo "Running example..."
if [ -f examples/basic/sqlite_example ]; then
    ./examples/basic/sqlite_example
    echo "Test completed successfully!"
else
    echo "Error: Example executable not found"
    exit 1
fi