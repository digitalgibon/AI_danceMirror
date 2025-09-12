#!/usr/bin/env bash

# Comprehensive GPU Diagnostic for AI Dance Mirror
# This script will identify why TensorFlow is using CPU instead of GPU

echo "=== Comprehensive GPU Diagnostic ==="
echo "Date: $(date)"
echo ""

# 1. Check NVIDIA GPU
echo "1. NVIDIA GPU Status:"
nvidia-smi --query-gpu=name,memory.total,memory.free,driver_version,cuda_version --format=csv,noheader,nounits
echo ""

# 2. Check CUDA installation
echo "2. CUDA Installation:"
if [ -d "/usr/local/cuda" ]; then
    echo "✓ CUDA found at: /usr/local/cuda"
    echo "CUDA version: $(cat /usr/local/cuda/version.json | grep -o '"version":"[^"]*"' | cut -d'"' -f4)"
    ls -la /usr/local/cuda/lib64/ | grep -E "libcudart|libcublas|libcufft|libcusparse|libcusolver" | head -5
else
    echo "✗ CUDA not found in /usr/local/cuda"
fi
echo ""

# 3. Check cuDNN
echo "3. cuDNN Status:"
if [ -d "$(pwd)/cudnn-linux-x86_64-9.1.0.70_cuda12-archive" ]; then
    echo "✓ cuDNN archive found"
    ls -la cudnn-linux-x86_64-9.1.0.70_cuda12-archive/lib/ | grep libcudnn
else
    echo "✗ cuDNN archive not found"
fi
echo ""

# 4. Check TensorFlow libraries
echo "4. TensorFlow Libraries:"
if [ -f "bin/libtensorflow.so.2.15.0" ]; then
    echo "✓ TensorFlow library found"
    echo "Library size: $(du -h bin/libtensorflow.so.2.15.0 | cut -f1)"
    echo "CUDA references in library:"
    strings bin/libtensorflow.so.2.15.0 | grep -i cuda | wc -l
else
    echo "✗ TensorFlow library not found"
fi
echo ""

# 5. Check library dependencies
echo "5. Library Dependencies:"
if [ -f "bin/AI_danceMirror" ]; then
    echo "Checking AI_danceMirror dependencies..."
    ldd bin/AI_danceMirror | grep -E "tensorflow|cuda|cudnn" || echo "No CUDA/TensorFlow dependencies found in binary"
else
    echo "✗ AI_danceMirror binary not found"
fi
echo ""

# 6. Check environment variables
echo "6. Environment Variables:"
echo "CUDA_HOME: ${CUDA_HOME:-NOT SET}"
echo "CUDA_ROOT: ${CUDA_ROOT:-NOT SET}"
echo "LD_LIBRARY_PATH: ${LD_LIBRARY_PATH:-NOT SET}"
echo "TF_CPP_MIN_LOG_LEVEL: ${TF_CPP_MIN_LOG_LEVEL:-NOT SET}"
echo "CUDA_VISIBLE_DEVICES: ${CUDA_VISIBLE_DEVICES:-NOT SET}"
echo ""

# 7. Test TensorFlow GPU detection
echo "7. TensorFlow GPU Detection Test:"
export CUDA_HOME=/usr/local/cuda
export LD_LIBRARY_PATH=$(pwd)/bin:/usr/local/cuda/lib64:$(pwd)/cudnn-linux-x86_64-9.1.0.70_cuda12-archive/lib:$LD_LIBRARY_PATH
export TF_CPP_MIN_LOG_LEVEL=0
export CUDA_VISIBLE_DEVICES=0

echo "Running quick TensorFlow GPU test..."
timeout 5s ./bin/AI_danceMirror > tf_gpu_test.log 2>&1 &
TF_PID=$!
sleep 3
kill $TF_PID 2>/dev/null

echo "TensorFlow logs (last 20 lines):"
tail -20 tf_gpu_test.log | grep -E "(GPU|CUDA|device|Cannot dlopen)" || echo "No GPU-related logs found"
echo ""

# 8. Check for missing libraries
echo "8. Missing Library Check:"
echo "Checking for required CUDA libraries..."
MISSING_LIBS=""
for lib in libcudart.so libcublas.so libcublasLt.so libcufft.so libcusparse.so libcusolver.so libcudnn.so; do
    if ! ldconfig -p | grep -q "$lib"; then
        MISSING_LIBS="$MISSING_LIBS $lib"
    fi
done

if [ -n "$MISSING_LIBS" ]; then
    echo "✗ Missing libraries:$MISSING_LIBS"
else
    echo "✓ All required CUDA libraries found"
fi
echo ""

# 9. Recommendations
echo "9. Recommendations:"
if [ -n "$MISSING_LIBS" ]; then
    echo "- Install missing CUDA libraries"
fi

if ! nvidia-smi > /dev/null 2>&1; then
    echo "- Install NVIDIA drivers"
fi

if [ ! -d "/usr/local/cuda" ]; then
    echo "- Install CUDA toolkit"
fi

if [ ! -f "bin/libtensorflow.so.2.15.0" ]; then
    echo "- Build/install TensorFlow with GPU support"
fi

echo ""
echo "=== Diagnostic Complete ==="
echo "Check the output above for specific issues."
