#!/bin/bash
# Solution C: Quick diagnostic without library conflicts

echo "=== SOLUTION C: Quick Model Inspection (No Runtime Conflicts) ==="
echo ""

# Use Python with TensorFlow to inspect the model safely
python3 -c "
import os
import sys

# Suppress TensorFlow warnings
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

try:
    import tensorflow as tf
    print('TensorFlow version:', tf.__version__)
    print()
    
    model_path = '/home/fryga/of_v0.11.2_linux64gcc6_release/apps/myApps/AI_danceMirror/bin/data/model'
    
    if os.path.exists(model_path):
        print('Inspecting SavedModel at:', model_path)
        
        # Load and inspect the model
        try:
            imported = tf.saved_model.load(model_path)
            print('Model loaded successfully!')
            
            # Get signature information
            signatures = imported.signatures
            print('Available signatures:', list(signatures.keys()))
            
            if 'serving_default' in signatures:
                signature = signatures['serving_default']
                print()
                print('serving_default signature:')
                print('Input tensors:')
                for name, spec in signature.inputs.items():
                    print(f'  {name}: {spec}')
                print('Output tensors:')
                for name, spec in signature.outputs.items():
                    print(f'  {name}: {spec}')
            
            # Try alternative inspection methods
            if hasattr(imported, 'call'):
                print()
                print('Model has callable interface')
                
        except Exception as e:
            print('Error loading model:', str(e))
    else:
        print('Model path not found:', model_path)
        
except ImportError:
    print('TensorFlow not available in Python environment')
    print('Install with: pip install tensorflow')
except Exception as e:
    print('Error:', str(e))
"

echo ""
echo "Alternative C API inspection (if Python TensorFlow unavailable):"
echo "================================================================"

# Create a minimal C program that just loads the model without conflicting libraries
cat > model_inspector.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>

// Minimal TensorFlow C API inspection
// This avoids the complex openFrameworks dependencies

int main() {
    printf("=== Minimal TensorFlow C API Model Inspector ===\n");
    printf("Model path: /home/fryga/of_v0.11.2_linux64gcc6_release/apps/myApps/AI_danceMirror/bin/data/model\n");
    
    // TODO: Add minimal TF_LoadSessionFromSavedModel call
    // This would require linking only the specific TensorFlow version we want to test
    
    printf("Use Python inspection above instead for now.\n");
    return 0;
}
EOF

echo "Created model_inspector.c for future C API testing"
echo ""
echo "RECOMMENDATION: Use Python inspection first to understand the model structure,"
echo "then implement the correct tensor names in the C++ code."
