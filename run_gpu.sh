#!/usr/bin/env bash

# GPU-enabled launch script for AI Dance Mirror
# This script sets up the environment for GPU acceleration with TensorFlow

echo "=== AI Dance Mirror GPU Setup ==="

# Set CUDA environment
export CUDA_HOME=/usr/local/cuda-12.5
export CUDA_ROOT=/usr/local/cuda-12.5

# Add GPU libraries to library path (bin first to ensure our GPU TensorFlow is used)
export LD_LIBRARY_PATH=$(pwd)/bin:$CUDA_HOME/lib64:$(pwd)/cudnn-linux-x86_64-9.1.0.70_cuda12-archive/lib:$LD_LIBRARY_PATH

# TensorFlow GPU configuration
export TF_FORCE_GPU_ALLOW_GROWTH=true
export TF_CPP_MIN_LOG_LEVEL=0  # Show all TensorFlow logs to verify GPU usage
export CUDA_VISIBLE_DEVICES=0  # Use first GPU

# Ensure we're in the right directory
cd "$(dirname "$0")"

echo "Environment variables:"
echo "CUDA_HOME: $CUDA_HOME"
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
echo "TF_CPP_MIN_LOG_LEVEL: $TF_CPP_MIN_LOG_LEVEL"

echo ""
echo "Checking NVIDIA driver and CUDA..."
nvidia-smi

echo ""
echo "Checking library dependencies..."
echo "TensorFlow library dependencies:"
ldd bin/AI_danceMirror | grep -E "tensorflow|cudart|cublas|cudnn" || echo "No CUDA libraries found in dependencies"

echo ""
echo "Checking if CUDA libraries are available:"
find /usr/local/cuda/lib64 -name "libcudart*" 2>/dev/null | head -3
find $(pwd)/cudnn-linux-x86_64-9.1.0.70_cuda12-archive/lib -name "libcudnn*" 2>/dev/null | head -3

echo ""
echo "Starting AI Dance Mirror with GPU acceleration..."
echo "Look for TensorFlow GPU device creation messages..."
echo ""

# Run the application
./bin/AI_danceMirror
