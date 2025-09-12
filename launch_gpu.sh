#!/usr/bin/env bash

# GPU-Enabled Launch Script for AI Dance Mirror
# This script ensures the application uses local GPU-enabled TensorFlow libraries

echo "=== AI Dance Mirror GPU Launch ==="

# Set CUDA environment
export CUDA_HOME=/usr/local/cuda
export CUDA_ROOT=/usr/local/cuda

# Prioritize local TensorFlow libraries over addon ones
export LD_LIBRARY_PATH=$(pwd)/bin:/usr/local/cuda/lib64:$(pwd)/cudnn-linux-x86_64-9.1.0.70_cuda12-archive/lib:$LD_LIBRARY_PATH

# TensorFlow GPU configuration
export TF_CPP_MIN_LOG_LEVEL=0  # Show all TensorFlow logs to verify GPU usage
export TF_FORCE_GPU_ALLOW_GROWTH=true
export CUDA_VISIBLE_DEVICES=0

echo "Environment setup:"
echo "CUDA_HOME: $CUDA_HOME"
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
echo "TF_CPP_MIN_LOG_LEVEL: $TF_CPP_MIN_LOG_LEVEL"
echo ""

# Check which TensorFlow libraries will be used
echo "TensorFlow library resolution:"
ldd bin/AI_danceMirror | grep tensorflow
echo ""

# Check NVIDIA GPU
echo "GPU Status:"
nvidia-smi --query-gpu=name,memory.used,memory.total --format=csv,noheader,nounits
echo ""

echo "Starting AI Dance Mirror with GPU acceleration..."
echo "Look for 'Created device /device:GPU:0' messages..."
echo ""

# Launch the application
./bin/AI_danceMirror
