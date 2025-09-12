#!/usr/bin/env bash

# Complete GPU Fix Script for AI Dance Mirror
# This script addresses all potential GPU issues

echo "=== Complete GPU Fix for AI Dance Mirror ==="

# 1. Check and fix CUDA environment
echo "1. Setting up CUDA environment..."
export CUDA_HOME=/usr/local/cuda
export CUDA_ROOT=/usr/local/cuda
export PATH=$CUDA_HOME/bin:$PATH

# 2. Check NVIDIA driver and CUDA compatibility
echo "2. Checking NVIDIA driver..."
nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits

# 3. Fix library loading order
echo "3. Configuring library paths..."
export LD_LIBRARY_PATH=$PWD/bin:$CUDA_HOME/lib64:$PWD/cudnn-linux-x86_64-9.1.0.70_cuda12-archive/lib:$LD_LIBRARY_PATH

# 4. Check for conflicting TensorFlow installations
echo "4. Checking for TensorFlow conflicts..."
if [ -d "/usr/local/lib" ]; then
    TF_CONFLICTS=$(find /usr/local/lib -name "*tensorflow*" 2>/dev/null | wc -l)
    if [ "$TF_CONFLICTS" -gt 0 ]; then
        echo "⚠️  Found $TF_CONFLICTS TensorFlow libraries in /usr/local/lib"
        echo "This might cause conflicts. Consider removing them."
    fi
fi

# 5. Test CUDA functionality
echo "5. Testing CUDA functionality..."
if command -v nvcc >/dev/null 2>&1; then
    echo "✓ CUDA compiler found"
else
    echo "✗ CUDA compiler not found"
fi

# 6. Check GPU memory and processes
echo "6. GPU status:"
nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu --format=csv,noheader,nounits

# 7. Create a clean launch environment
echo "7. Creating clean launch environment..."

# Kill any existing processes that might interfere
pkill -f "AI_danceMirror" 2>/dev/null || true

# Clear any cached libraries
if command -v ldconfig >/dev/null 2>&1; then
    sudo ldconfig 2>/dev/null || true
fi

# 8. Set TensorFlow environment variables
echo "8. Configuring TensorFlow..."
export TF_CPP_MIN_LOG_LEVEL=0
export TF_FORCE_GPU_ALLOW_GROWTH=true
export CUDA_VISIBLE_DEVICES=0
export TF_ENABLE_GPU_GARBAGE_COLLECTION=false

# 9. Test TensorFlow GPU detection
echo "9. Testing TensorFlow GPU detection..."
echo "Running quick test..."

timeout 8s ./bin/AI_danceMirror > gpu_test.log 2>&1 &
APP_PID=$!

# Wait a bit for initialization
sleep 5

# Check if GPU messages appeared
if grep -q "Created device /device:GPU:0" gpu_test.log; then
    echo "✅ SUCCESS: TensorFlow GPU device detected!"
elif grep -q "Skipping registering GPU devices" gpu_test.log; then
    echo "❌ FAILURE: TensorFlow is skipping GPU registration"
elif grep -q "CUDA_ERROR" gpu_test.log; then
    echo "❌ FAILURE: CUDA error detected"
    grep "CUDA_ERROR" gpu_test.log
else
    echo "⚠️  UNCLEAR: No clear GPU detection messages found"
fi

# Kill the test process
kill $APP_PID 2>/dev/null || true
wait $APP_PID 2>/dev/null || true

echo ""
echo "=== GPU Fix Complete ==="
echo "Log saved to: gpu_test.log"
echo ""
echo "If GPU detection failed, try these solutions:"
echo "1. Reboot the system"
echo "2. Check NVIDIA driver: nvidia-smi"
echo "3. Verify CUDA installation: nvcc --version"
echo "4. Run: sudo nvidia-modprobe"
echo "5. Check kernel modules: lsmod | grep nvidia"
echo ""
echo "To launch with GPU: ./launch_gpu.sh"
