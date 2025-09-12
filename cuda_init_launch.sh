#!/usr/bin/env bash

# CUDA Initialization and GPU Launch Script
# This script properly initializes CUDA before launching the application

echo "=== CUDA Initialization and GPU Launch ==="

# Set environment variables
export CUDA_HOME=/usr/local/cuda
export CUDA_ROOT=/usr/local/cuda
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$PWD/bin:$CUDA_HOME/lib64:$PWD/cudnn-linux-x86_64-9.1.0.70_cuda12-archive/lib:$LD_LIBRARY_PATH

# TensorFlow configuration
export TF_CPP_MIN_LOG_LEVEL=0
export TF_FORCE_GPU_ALLOW_GROWTH=true
export CUDA_VISIBLE_DEVICES=0

echo "Initializing CUDA..."

# Try to initialize CUDA by running a simple CUDA command
if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi -q >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✓ NVIDIA driver accessible"
    else
        echo "✗ NVIDIA driver not accessible"
        exit 1
    fi
else
    echo "✗ nvidia-smi not found"
    exit 1
fi

# Test CUDA initialization with a simple program
echo "Testing CUDA initialization..."
cat > /tmp/cuda_test.cu << 'EOF'
#include <cuda_runtime.h>
#include <iostream>

int main() {
    int deviceCount;
    cudaError_t error = cudaGetDeviceCount(&deviceCount);
    if (error != cudaSuccess) {
        std::cerr << "CUDA error: " << cudaGetErrorString(error) << std::endl;
        return 1;
    }
    std::cout << "CUDA devices found: " << deviceCount << std::endl;
    return 0;
}
EOF

# Compile and run CUDA test
if command -v nvcc >/dev/null 2>&1; then
    nvcc /tmp/cuda_test.cu -o /tmp/cuda_test 2>/dev/null
    if [ -f /tmp/cuda_test ]; then
        /tmp/cuda_test
        if [ $? -eq 0 ]; then
            echo "✓ CUDA initialization successful"
        else
            echo "✗ CUDA initialization failed"
        fi
    else
        echo "⚠️  Could not compile CUDA test program"
    fi
else
    echo "⚠️  nvcc not found, skipping CUDA test"
fi

# Clean up
rm -f /tmp/cuda_test.cu /tmp/cuda_test

echo ""
echo "Launching AI Dance Mirror with GPU support..."
echo "Monitor for 'Created device /device:GPU:0' messages..."
echo ""

# Launch the application
exec ./bin/AI_danceMirror
