#!/usr/bin/env bash

# Comprehensive GPU verification script for AI Dance Mirror
# This script will verify if all GPU requirements are met

echo "=== AI Dance Mirror GPU Requirements Verification ==="

# Function to check and report status
check_status() {
    if [ $1 -eq 0 ]; then
        echo "✓ $2"
        return 0
    else
        echo "✗ $2"
        return 1
    fi
}

FAIL_COUNT=0

# 1. Check NVIDIA GPU
echo ""
echo "1. Checking NVIDIA GPU..."
nvidia-smi > /dev/null 2>&1
if ! check_status $? "NVIDIA GPU detected"; then
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# 2. Check CUDA installation
echo ""
echo "2. Checking CUDA installation..."
nvcc --version > /dev/null 2>&1
if ! check_status $? "CUDA compiler available"; then
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# Check CUDA runtime libraries
if [ -f "/usr/local/cuda/lib64/libcudart.so" ]; then
    echo "✓ CUDA runtime libraries found"
else
    echo "✗ CUDA runtime libraries not found"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# 3. Check cuDNN libraries
echo ""
echo "3. Checking cuDNN libraries..."
if [ -f "/usr/local/cuda/lib64/libcudnn.so" ]; then
    echo "✓ cuDNN libraries found in system"
elif [ -f "$(pwd)/cudnn-linux-x86_64-9.1.0.70_cuda12-archive/lib/libcudnn.so.9.1.0" ]; then
    echo "✓ cuDNN libraries found locally"
else
    echo "✗ cuDNN libraries not found"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# 4. Check TensorFlow libraries
echo ""
echo "4. Checking TensorFlow libraries..."
if [ -f "bin/libtensorflow.so.2.15.0" ]; then
    echo "✓ TensorFlow libraries found"
    
    # Check if TensorFlow has CUDA symbols
    if strings bin/libtensorflow.so.2.15.0 | grep -q "cuda"; then
        echo "✓ TensorFlow appears to have CUDA support compiled in"
    else
        echo "✗ TensorFlow may not have CUDA support"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
else
    echo "✗ TensorFlow libraries not found"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# 5. Check application binary
echo ""
echo "5. Checking application binary..."
if [ -f "bin/AI_danceMirror" ]; then
    echo "✓ AI_danceMirror binary exists"
else
    echo "✗ AI_danceMirror binary not found - run 'make' first"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# 6. Test GPU detection with minimal run
echo ""
echo "6. Testing GPU detection with application..."
export CUDA_HOME=/usr/local/cuda
export LD_LIBRARY_PATH=$(pwd)/bin:$CUDA_HOME/lib64:$(pwd)/cudnn-linux-x86_64-9.1.0.70_cuda12-archive/lib:$LD_LIBRARY_PATH
export TF_CPP_MIN_LOG_LEVEL=0
export CUDA_VISIBLE_DEVICES=0

if [ -f "bin/AI_danceMirror" ]; then
    # Run app for 3 seconds to check GPU initialization
    timeout 3s ./bin/AI_danceMirror 2>&1 | grep -E "(GPU|device|CUDA)" | head -10
    
    # Check the log output for GPU detection
    timeout 3s ./bin/AI_danceMirror 2>&1 | grep -q "Skipping registering GPU devices"
    if [ $? -eq 0 ]; then
        echo "✗ TensorFlow is skipping GPU device registration"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    else
        echo "✓ TensorFlow GPU initialization appears to be working"
    fi
fi

echo ""
echo "=== Summary ==="
if [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ All GPU requirements satisfied!"
    echo "✅ Your application should run with GPU acceleration."
    echo ""
    echo "To run the application:"
    echo "  ./run_gpu.sh"
    exit 0
else
    echo "❌ $FAIL_COUNT issues found!"
    echo "❌ GPU acceleration may not work properly."
    echo "❌ The application will exit if GPU is not available."
    echo ""
    echo "Common fixes:"
    echo "  1. Install NVIDIA drivers: sudo apt install nvidia-driver-535"
    echo "  2. Install CUDA: sudo apt install nvidia-cuda-toolkit"
    echo "  3. Run setup script: sudo ./setup_gpu_libs.sh"
    echo "  4. Recompile TensorFlow with GPU support"
    exit 1
fi
