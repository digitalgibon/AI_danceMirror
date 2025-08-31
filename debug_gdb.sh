#!/bin/bash

# GDB Debug Script for AI_danceMirror
# This script sets up GDB for debugging TensorFlow/CUDA issues

echo "=== Setting up GDB Debug Session ==="

# Source environment
source ./debug_env.sh

# Clean and build with debug flags
echo "Building with debug flags..."
make clean
make

if [ $? -ne 0 ]; then
    echo "Build failed! Check compilation errors above."
    exit 1
fi

echo ""
echo "=== Starting GDB Debug Session ==="
echo "Useful GDB commands:"
echo "  (gdb) b main                    # Break at main"
echo "  (gdb) b ofApp::setup           # Break at ofApp setup"
echo "  (gdb) b ImageToImageModel::runModel  # Break at model execution"
echo "  (gdb) r                        # Run the program"
echo "  (gdb) bt                       # Show backtrace"
echo "  (gdb) p variable_name          # Print variable value"
echo "  (gdb) c                        # Continue execution"
echo "  (gdb) s                        # Step into"
echo "  (gdb) n                        # Step over"
echo "  (gdb) q                        # Quit GDB"
echo ""

# Start GDB with the executable
gdb --args ./bin/AI_danceMirror
