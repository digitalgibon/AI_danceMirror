#!/usr/bin/env bash

# Setup GPU libraries for TensorFlow GPU support
# This script will copy necessary CUDA and cuDNN libraries to system locations

echo "=== Setting up GPU libraries for TensorFlow ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script needs to be run with sudo to copy libraries to system locations"
    echo "Usage: sudo ./setup_gpu_libs.sh"
    exit 1
fi

# Create symbolic links for CUDA if not already present
if [ ! -L "/usr/local/cuda" ]; then
    echo "Creating CUDA symlink..."
    ln -sf /usr/local/cuda-12.5 /usr/local/cuda
    echo "✓ CUDA symlink created: /usr/local/cuda -> /usr/local/cuda-12.5"
else
    echo "✓ CUDA symlink already exists"
fi

# Copy cuDNN libraries to CUDA installation
CUDNN_SOURCE="./cudnn-linux-x86_64-9.1.0.70_cuda12-archive"
CUDA_LIB_DIR="/usr/local/cuda/lib64"
CUDA_INCLUDE_DIR="/usr/local/cuda/include"

echo "Copying cuDNN libraries..."

# Copy cuDNN libraries
if [ -d "$CUDNN_SOURCE/lib" ]; then
    cp -f $CUDNN_SOURCE/lib/libcudnn*.so.* $CUDA_LIB_DIR/
    
    # Create symlinks for cuDNN
    cd $CUDA_LIB_DIR
    
    # Main cuDNN library
    ln -sf libcudnn.so.9.1.0 libcudnn.so.9 2>/dev/null
    ln -sf libcudnn.so.9 libcudnn.so 2>/dev/null
    
    # cuDNN component libraries
    for lib in adv cnn graph ops engines_precompiled engines_runtime_compiled; do
        if [ -f "libcudnn_${lib}.so.9.1.0" ]; then
            ln -sf libcudnn_${lib}.so.9.1.0 libcudnn_${lib}.so.9 2>/dev/null
            ln -sf libcudnn_${lib}.so.9 libcudnn_${lib}.so 2>/dev/null
        fi
    done
    
    echo "✓ cuDNN libraries copied and symlinked"
else
    echo "✗ cuDNN source directory not found: $CUDNN_SOURCE/lib"
fi

# Copy cuDNN headers
if [ -d "$CUDNN_SOURCE/include" ]; then
    cp -f $CUDNN_SOURCE/include/cudnn*.h $CUDA_INCLUDE_DIR/
    echo "✓ cuDNN headers copied"
else
    echo "✗ cuDNN include directory not found: $CUDNN_SOURCE/include"
fi

# Update library cache
echo "Updating library cache..."
echo "/usr/local/cuda/lib64" > /etc/ld.so.conf.d/cuda.conf
ldconfig

echo ""
echo "=== Verification ==="
echo "Checking if libraries are now available:"

# Check if libraries can be found
echo "libcudart.so:"
ldconfig -p | grep libcudart | head -1

echo "libcublas.so:"
ldconfig -p | grep libcublas | head -1

echo "libcudnn.so:"
ldconfig -p | grep libcudnn | head -1

echo ""
echo "=== Setup Complete ==="
echo "You can now run the application with GPU support."
echo "Use: ./run_gpu.sh"
