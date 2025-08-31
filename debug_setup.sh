#!/bin/bash
# TensorFlow + CUDA 12.5 Environment Setup and Debug Script

echo "=== TensorFlow + CUDA 12.5 Debug Environment Setup ==="

# Set environment variables for debugging
export TF_CPP_MIN_LOG_LEVEL=0  # Show all TensorFlow logs
export TF_CPP_MIN_VLOG_LEVEL=1 # Verbose logging
export CUDA_VISIBLE_DEVICES=0  # Use first GPU
export CUDA_LAUNCH_BLOCKING=1  # Synchronous CUDA calls for better debugging

# CUDA and cuDNN paths
export CUDA_HOME=/usr/local/cuda-12.5
export CUDA_ROOT=$CUDA_HOME
export PATH=$CUDA_HOME/bin:$PATH

# Library paths for your project
PROJECT_ROOT="/home/fryga/of_v0.11.2_linux64gcc6_release/apps/myApps/AI_danceMirror"
export LD_LIBRARY_PATH="$PROJECT_ROOT/bin:$PROJECT_ROOT/lib:$CUDA_HOME/lib64:$PROJECT_ROOT/cudnn-linux-x86_64-9.1.0.70_cuda12-archive/lib:$LD_LIBRARY_PATH"

echo "Environment variables set:"
echo "CUDA_HOME: $CUDA_HOME"
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
echo "TF_CPP_MIN_LOG_LEVEL: $TF_CPP_MIN_LOG_LEVEL"

echo ""
echo "=== System Information ==="
echo "CUDA Version:"
nvcc --version | grep "release"
echo ""
echo "NVIDIA Driver:"
nvidia-smi | grep "Driver Version" | head -1
echo ""
echo "TensorFlow Libraries:"
ls -la $PROJECT_ROOT/bin/*tensorflow* 2>/dev/null || echo "No TensorFlow libraries found in bin/"
ls -la $PROJECT_ROOT/lib/*tensorflow* 2>/dev/null || echo "No TensorFlow libraries found in lib/"

echo ""
echo "=== Build and Run Options ==="
echo "1. make clean && make Debug  - Build with debug symbols"
echo "2. make run                  - Run with current debugging"
echo "3. gdb --args ./bin/AI_danceMirror - Run with GDB debugger"
echo ""

# Function to build debug version
build_debug() {
    echo "Building debug version..."
    cd "$PROJECT_ROOT"
    make clean
    make Debug -j$(nproc)
}

# Function to run with debugging
run_debug() {
    echo "Running with debugging enabled..."
    cd "$PROJECT_ROOT"
    ./bin/AI_danceMirror
}

# Function to run with GDB
run_gdb() {
    echo "Starting GDB session..."
    echo "Useful GDB commands:"
    echo "  (gdb) b main"
    echo "  (gdb) b ofApp::setup"
    echo "  (gdb) b ImageToImageModel::setupWithNameDetection"
    echo "  (gdb) r"
    echo "  (gdb) bt  (for backtrace when error occurs)"
    echo "  (gdb) c   (to continue execution)"
    cd "$PROJECT_ROOT"
    gdb --args ./bin/AI_danceMirror
}

# Check for command line arguments
case "${1:-}" in
    "build")
        build_debug
        ;;
    "run")
        run_debug
        ;;
    "gdb")
        run_gdb
        ;;
    *)
        echo "Usage: $0 [build|run|gdb]"
        echo "  build - Clean and build debug version"
        echo "  run   - Run with debugging"
        echo "  gdb   - Run with GDB debugger"
        echo ""
        echo "Current environment is set up. You can now:"
        echo "  cd $PROJECT_ROOT"
        echo "  make clean && make Debug"
        echo "  make run"
        ;;
esac
