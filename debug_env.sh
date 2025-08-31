#!/bin/bash

# TensorFlow/CUDA Debug Environment Setup
# This script sets up environment variables for debugging TensorFlow with CUDA 12.5

echo "=== Setting up TensorFlow/CUDA Debug Environment ==="

# TensorFlow logging
export TF_CPP_MIN_LOG_LEVEL=0  # Show all TensorFlow logs (0=INFO, 1=WARN, 2=ERROR, 3=FATAL)
export TF_CPP_MIN_VLOG_LEVEL=1 # Verbose logging for device placement

# CUDA paths
export CUDA_HOME=/usr/local/cuda-12.5
export CUDA_ROOT=/usr/local/cuda-12.5
export PATH=$CUDA_HOME/bin:$PATH

# Library paths
export LD_LIBRARY_PATH=/usr/local/cuda-12.5/lib64:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/home/fryga/of_v0.11.2_linux64gcc6_release/apps/myApps/AI_danceMirror/cudnn-linux-x86_64-9.1.0.70_cuda12-archive/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/home/fryga/of_v0.11.2_linux64gcc6_release/addons/ofxTensorFlow2/libs/tensorflow/lib/linux64:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/home/fryga/of_v0.11.2_linux64gcc6_release/apps/myApps/AI_danceMirror/lib:$LD_LIBRARY_PATH

# TensorFlow specific
export TF_FORCE_GPU_ALLOW_GROWTH=true
export TF_GPU_ALLOCATOR=cuda_malloc_async

# CUDA debugging
export CUDA_VISIBLE_DEVICES=0  # Use first GPU
export CUDA_LAUNCH_BLOCKING=1  # Synchronous CUDA operations for debugging

echo "Environment variables set:"
echo "TF_CPP_MIN_LOG_LEVEL: $TF_CPP_MIN_LOG_LEVEL"
echo "TF_CPP_MIN_VLOG_LEVEL: $TF_CPP_MIN_VLOG_LEVEL"
echo "CUDA_HOME: $CUDA_HOME"
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
echo ""

# Check CUDA installation
echo "=== CUDA Installation Check ==="
if command -v nvcc &> /dev/null; then
    echo "NVCC version:"
    nvcc --version
else
    echo "WARNING: nvcc not found in PATH"
fi

if command -v nvidia-smi &> /dev/null; then
    echo "GPU status:"
    nvidia-smi -L
else
    echo "WARNING: nvidia-smi not found"
fi

echo ""
echo "=== Library Check ==="
echo "Checking TensorFlow libraries:"
ls -la /home/fryga/of_v0.11.2_linux64gcc6_release/addons/ofxTensorFlow2/libs/tensorflow/lib/linux64/libtensorflow*

echo ""
echo "Checking CUDA libraries:"
ls -la /usr/local/cuda-12.5/lib64/libcuda*

echo ""
echo "=== Ready to run with debugging ==="
echo "Use: source debug_env.sh && make clean && make && ./bin/AI_danceMirror"
echo "Or for GDB debugging: source debug_env.sh && make clean && make && gdb --args ./bin/AI_danceMirror"
