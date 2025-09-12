#!/usr/bin/env bash

# Final GPU Fix - Reboot Required Solution
# This script prepares the system for GPU usage and requires a reboot

echo "=== Final GPU Fix for AI Dance Mirror ==="
echo "This fix requires a system reboot to take effect."
echo ""

# 1. Check current status
echo "1. Current GPU status:"
nvidia-smi --query-gpu=name,driver_version --format=csv,noheader

# 2. Clean up any conflicting installations
echo ""
echo "2. Cleaning up potential conflicts..."

# Remove any system TensorFlow installations that might conflict
if [ -d "/usr/local/lib" ]; then
    TF_SYSTEM=$(find /usr/local/lib -name "*tensorflow*" 2>/dev/null | wc -l)
    if [ "$TF_SYSTEM" -gt 0 ]; then
        echo "Found $TF_SYSTEM TensorFlow libraries in system paths"
        echo "These might conflict with local GPU libraries"
    fi
fi

# 3. Ensure CUDA libraries are properly linked
echo ""
echo "3. Ensuring CUDA library links..."
sudo ldconfig

# 4. Create a persistent environment file
echo ""
echo "4. Creating persistent GPU environment..."

cat > ~/.gpu_env << 'EOF'
# GPU Environment for AI Dance Mirror
export CUDA_HOME=/usr/local/cuda
export CUDA_ROOT=/usr/local/cuda
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=/home/fryga/of_v0.11.2_linux64gcc6_release/apps/myApps/AI_danceMirror/bin:$CUDA_HOME/lib64:/home/fryga/of_v0.11.2_linux64gcc6_release/apps/myApps/AI_danceMirror/cudnn-linux-x86_64-9.1.0.70_cuda12-archive/lib:$LD_LIBRARY_PATH
export TF_CPP_MIN_LOG_LEVEL=0
export TF_FORCE_GPU_ALLOW_GROWTH=true
export CUDA_VISIBLE_DEVICES=0
EOF

echo "Created ~/.gpu_env with GPU environment variables"

# 5. Create a desktop launcher
echo ""
echo "5. Creating desktop launcher..."

cat > ~/Desktop/AI_Dance_Mirror_GPU.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=AI Dance Mirror (GPU)
Comment=Real-time style transfer with GPU acceleration
Exec=bash -c "source ~/.gpu_env && cd /home/fryga/of_v0.11.2_linux64gcc6_release/apps/myApps/AI_danceMirror && ./bin/AI_danceMirror"
Icon=applications-graphics
Terminal=false
StartupWMClass=AI_danceMirror
EOF

chmod +x ~/Desktop/AI_Dance_Mirror_GPU.desktop
echo "Created desktop launcher: ~/Desktop/AI_Dance_Mirror_GPU.desktop"

# 6. Create final launch script
echo ""
echo "6. Creating final launch script..."

cat > /home/fryga/of_v0.11.2_linux64gcc6_release/apps/myApps/AI_danceMirror/final_gpu_launch.sh << 'EOF'
#!/usr/bin/env bash

echo "=== Final GPU Launch for AI Dance Mirror ==="

# Source environment
if [ -f ~/.gpu_env ]; then
    source ~/.gpu_env
    echo "✓ GPU environment loaded"
else
    echo "✗ GPU environment file not found"
    exit 1
fi

# Verify GPU access
echo "GPU Status:"
nvidia-smi --query-gpu=name,memory.used,memory.total --format=csv,noheader,nounits

# Check library resolution
echo ""
echo "TensorFlow library resolution:"
ldd bin/AI_danceMirror | grep tensorflow

echo ""
echo "Starting AI Dance Mirror with GPU acceleration..."
echo "Look for GPU device creation messages..."
echo ""

# Launch with clean environment
exec ./bin/AI_danceMirror
EOF

chmod +x /home/fryga/of_v0.11.2_linux64gcc6_release/apps/myApps/AI_danceMirror/final_gpu_launch.sh

echo ""
echo "=== Setup Complete ==="
echo ""
echo "IMPORTANT: You need to REBOOT your system for GPU changes to take effect!"
echo ""
echo "After reboot, use one of these methods to launch:"
echo ""
echo "Method 1 - Desktop launcher:"
echo "  Double-click 'AI Dance Mirror (GPU)' on your desktop"
echo ""
echo "Method 2 - Terminal:"
echo "  cd /home/fryga/of_v0.11.2_linux64gcc6_release/apps/myApps/AI_danceMirror"
echo "  ./final_gpu_launch.sh"
echo ""
echo "Method 3 - Direct:"
echo "  source ~/.gpu_env"
echo "  ./bin/AI_danceMirror"
echo ""
echo "To verify GPU usage, look for these messages:"
echo "  'Created device /device:GPU:0'"
echo "  'Successfully opened CUDA library libcudart.so'"
echo ""
echo "Press Enter to reboot now, or Ctrl+C to cancel..."
read -p ""

echo "Rebooting system..."
sudo reboot
EOF

chmod +x /home/fryga/of_v0.11.2_linux64gcc6_release/apps/myApps/AI_danceMirror/final_gpu_launch.sh

echo ""
echo "=== Final Setup Complete ==="
echo ""
echo "Run this command to start the final setup (requires reboot):"
echo "  ./final_gpu_launch.sh"
echo ""
echo "Or run these commands manually:"
echo "  source ~/.gpu_env"
echo "  ./bin/AI_danceMirror"
echo ""
echo "The final_gpu_launch.sh script will guide you through the reboot process."
