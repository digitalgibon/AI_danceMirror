#!/usr/bin/env bash

echo "=== TensorFlow Library Conflict Check ==="

# Check for multiple TensorFlow installations
echo "Checking for TensorFlow libraries in system paths..."

echo "1. /usr/lib paths:"
find /usr/lib* -name "*tensorflow*" 2>/dev/null | head -10

echo "2. /usr/local/lib paths:"
find /usr/local/lib* -name "*tensorflow*" 2>/dev/null | head -10

echo "3. Current project bin:"
ls -la bin/libtensorflow* 2>/dev/null

echo ""
echo "=== Library Dependencies Check ==="
if [ -f "bin/AI_danceMirror" ]; then
    echo "Checking AI_danceMirror dependencies:"
    ldd bin/AI_danceMirror | grep -E "tensorflow|cuda"
else
    echo "AI_danceMirror binary not found. Build the project first."
fi

echo ""
echo "=== CUDA Library Check ==="
echo "CUDA runtime libraries:"
find /usr/local/cuda*/lib* -name "libcudart*" 2>/dev/null | head -5

echo "cuBLAS libraries:"
find /usr/local/cuda*/lib* -name "libcublas*" 2>/dev/null | head -5

echo "Local cuDNN libraries:"
find $(pwd)/cudnn-linux-x86_64-9.1.0.70_cuda12-archive/lib -name "libcudnn.so*" 2>/dev/null

echo ""
echo "=== Environment Variables ==="
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
echo "CUDA_HOME: $CUDA_HOME"
echo "TF_CPP_MIN_LOG_LEVEL: $TF_CPP_MIN_LOG_LEVEL"
