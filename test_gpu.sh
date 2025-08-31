#!/usr/bin/env bash

# Quick GPU test for AI Dance Mirror
# This script will check if TensorFlow detects and uses GPU

echo "=== Quick GPU Detection Test ==="

# Set environment for GPU
export CUDA_HOME=/usr/local/cuda
export LD_LIBRARY_PATH=$(pwd)/bin:$CUDA_HOME/lib64:$(pwd)/cudnn-linux-x86_64-9.1.0.70_cuda12-archive/lib:$LD_LIBRARY_PATH
export TF_CPP_MIN_LOG_LEVEL=0  # Show all TensorFlow logs
export CUDA_VISIBLE_DEVICES=0

echo "Testing if TensorFlow can find GPU devices..."
echo "Environment configured for GPU acceleration"
echo ""

# Run the application in background for 10 seconds to capture GPU logs
timeout 10s ./bin/AI_danceMirror &
APP_PID=$!

echo "AI_danceMirror started (PID: $APP_PID)"
echo "Capturing TensorFlow GPU initialization logs for 10 seconds..."
echo ""

# Wait for the timeout or app to finish
wait $APP_PID 2>/dev/null

echo ""
echo "=== Test completed ==="
echo "If you saw messages like:"
echo "  'Created device /device:GPU:0'"
echo "  'Physical devices with 0 GPU'"  
echo "  'Device placement' messages"
echo "Then GPU acceleration is working!"
echo ""
echo "If you only see CPU messages or no device messages,"
echo "then it's still running on CPU."
