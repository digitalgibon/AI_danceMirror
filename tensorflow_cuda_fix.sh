#!/bin/bash
# TensorFlow CUDA 12.5 Compatibility Setup Script

echo "=== TensorFlow CUDA 12.5 Compatibility Setup ==="
echo ""
echo "ANALYSIS OF YOUR CURRENT SITUATION:"
echo "- You have CUDA 12.5 installed (confirmed)"
echo "- You have conflicting TensorFlow versions (2.8.0 and 2.13.0)"
echo "- TensorFlow 2.8.0 and 2.13.0 are NOT compatible with CUDA 12.5"
echo "- The error 'No operation named serving_default_input_1' suggests input/output name mismatch"
echo ""

PROJECT_ROOT="/home/fryga/of_v0.11.2_linux64gcc6_release/apps/myApps/AI_danceMirror"

echo "RECOMMENDED SOLUTIONS (choose one):"
echo ""
echo "=== OPTION A: Use Compatible CUDA Version (FAST) ==="
echo "1. Downgrade to CUDA 11.8 + cuDNN 8.6"
echo "   - TensorFlow 2.13 officially supports CUDA 11.8"
echo "   - Fastest solution, just change CUDA version"
echo "   - Install: sudo apt install nvidia-cuda-toolkit-11-8"
echo ""

echo "=== OPTION B: Build TensorFlow 2.16+ for CUDA 12.5 (SLOW) ==="
echo "TensorFlow 2.16+ has experimental CUDA 12.x support"
echo "This requires building from source (several hours):"
echo ""
echo "Prerequisites:"
echo "  - Python 3.10+"
echo "  - Bazel (matching TF version)"
echo "  - CUDA 12.5 toolkit"
echo "  - cuDNN 9.1"
echo ""
echo "Build steps:"
echo "  git clone https://github.com/tensorflow/tensorflow.git"
echo "  cd tensorflow && git checkout v2.16.0"
echo "  TF_NEED_CUDA=1 ./configure"
echo "  bazel build -c dbg --config=cuda tensorflow:libtensorflow.so"
echo ""

echo "=== OPTION C: Quick Debug with Input/Output Names (RECOMMENDED) ==="
echo "Try to fix the current setup by correcting input/output names first"
echo ""

echo "=== CURRENT LIBRARY STATUS ==="
cd "$PROJECT_ROOT"
echo "TensorFlow libraries in your project:"
ls -la bin/lib*tensorflow* 2>/dev/null | head -10
ls -la lib/lib*tensorflow* 2>/dev/null | head -10
echo ""

check_tensorflow_version() {
    echo "Checking which TensorFlow version is being used:"
    
    # Check which libraries are linked
    if [ -f "bin/AI_danceMirror" ]; then
        echo "Current binary links to:"
        ldd bin/AI_danceMirror | grep tensorflow || echo "No tensorflow libraries linked"
    else
        echo "Binary not built yet"
    fi
}

run_current_debug() {
    echo ""
    echo "=== RUNNING CURRENT DEBUG VERSION ==="
    echo "Setting environment for current libraries..."
    
    export TF_CPP_MIN_LOG_LEVEL=0
    export LD_LIBRARY_PATH="$PROJECT_ROOT/bin:$PROJECT_ROOT/lib:$LD_LIBRARY_PATH"
    
    echo "Building with current setup..."
    make clean
    make Debug -j$(nproc)
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "Build successful! Running with debug output..."
        echo ""
        ./bin/AI_danceMirror
    else
        echo "Build failed! Check compilation errors above."
    fi
}

prepare_cuda_11_8() {
    echo ""
    echo "=== PREPARING FOR CUDA 11.8 DOWNGRADE ==="
    echo ""
    echo "To install CUDA 11.8 (recommended for TensorFlow compatibility):"
    echo ""
    echo "1. Download CUDA 11.8:"
    echo "   wget https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda_11.8.0_520.61.05_linux.run"
    echo ""
    echo "2. Install CUDA 11.8:"
    echo "   sudo sh cuda_11.8.0_520.61.05_linux.run"
    echo ""
    echo "3. Update your config.make:"
    echo "   PROJECT_CFLAGS += -I/usr/local/cuda-11.8/include"
    echo ""
    echo "4. Download compatible TensorFlow 2.13 for CUDA 11.8:"
    echo "   wget https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-gpu-linux-x86_64-2.13.0.tar.gz"
    echo ""
    echo "5. Extract and replace current libraries"
}

build_tensorflow_cuda_12() {
    echo ""
    echo "=== BUILDING TENSORFLOW FOR CUDA 12.5 ==="
    echo ""
    echo "WARNING: This will take several hours!"
    echo ""
    read -p "Do you want to proceed with building TensorFlow from source? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Starting TensorFlow build process..."
        echo "This script will guide you through the build process."
        echo ""
        echo "First, install dependencies:"
        echo "sudo apt update"
        echo "sudo apt install python3-dev python3-pip build-essential"
        echo "pip3 install numpy wheel packaging requests opt_einsum"
        echo ""
        echo "Install Bazel (version matching TensorFlow):"
        echo "Check tensorflow/.bazelversion after cloning for exact version"
    else
        echo "Build cancelled."
    fi
}

# Check command line arguments
case "${1:-}" in
    "debug")
        check_tensorflow_version
        run_current_debug
        ;;
    "cuda11")
        prepare_cuda_11_8
        ;;
    "build-tf")
        build_tensorflow_cuda_12
        ;;
    "info")
        check_tensorflow_version
        ;;
    *)
        echo ""
        echo "USAGE: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  debug    - Try to run current setup with debugging"
        echo "  cuda11   - Show instructions for CUDA 11.8 setup"
        echo "  build-tf - Guide for building TensorFlow from source"
        echo "  info     - Show current library information"
        echo ""
        echo "RECOMMENDED NEXT STEPS:"
        echo "1. First try: $0 debug"
        echo "   This will attempt to fix input/output names"
        echo ""
        echo "2. If that fails: $0 cuda11"
        echo "   This shows how to downgrade to compatible CUDA 11.8"
        echo ""
        echo "3. Last resort: $0 build-tf"
        echo "   This guides you through building TensorFlow for CUDA 12.5"
        ;;
esac
