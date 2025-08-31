#!/usr/bin/env bash

# Final GPU test - test actual GPU usage during style transfer
echo "=== Final GPU Usage Test ==="

export CUDA_HOME=/usr/local/cuda
export LD_LIBRARY_PATH=$(pwd)/bin:$CUDA_HOME/lib64:$(pwd)/cudnn-linux-x86_64-9.1.0.70_cuda12-archive/lib:$LD_LIBRARY_PATH
export TF_CPP_MIN_LOG_LEVEL=0
export CUDA_VISIBLE_DEVICES=0

echo "Testing actual GPU usage during style transfer..."
echo ""

# Start nvidia-smi monitoring in background
nvidia-smi dmon -i 0 -s pucvmet -d 2 -c 10 > gpu_usage.log 2>&1 &
NVIDIA_PID=$!

echo "Starting AI_danceMirror with GPU monitoring..."
timeout 15s ./bin/AI_danceMirror > app_output.log 2>&1 &
APP_PID=$!

# Wait for app to finish or timeout
wait $APP_PID

# Stop nvidia monitoring
kill $NVIDIA_PID 2>/dev/null

echo ""
echo "=== Application Output Summary ==="
# Show key lines from app output
grep -E "(GPU|device|CUDA|TensorFlow|Style transfer)" app_output.log | head -10

echo ""
echo "=== GPU Usage Analysis ==="
if [ -f gpu_usage.log ]; then
    echo "GPU monitoring results:"
    echo "GPU Memory Usage:"
    awk 'NR>1 && $6 > 0 {print "  GPU Memory: " $6 " MB at " strftime("%H:%M:%S", systime())}' gpu_usage.log | head -5
    
    # Check if GPU was actually used
    GPU_MEM_USAGE=$(awk 'NR>1 && $6 > 0 {count++} END {print count+0}' gpu_usage.log)
    if [ "$GPU_MEM_USAGE" -gt 0 ]; then
        echo "✅ GPU WAS USED! Memory allocation detected during processing."
    else
        echo "❌ GPU was NOT used. No memory allocation detected."
    fi
else
    echo "❌ GPU monitoring failed"
fi

echo ""
echo "=== Results Summary ==="
echo "Check app_output.log for detailed TensorFlow logs"
echo "Check gpu_usage.log for GPU usage details"

# Clean up
rm -f gpu_usage.log app_output.log
