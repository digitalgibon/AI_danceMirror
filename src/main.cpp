#include "ofMain.h"
#include "ofApp.h"
#include "tensorflow/c/c_api.h"
#include <iostream>
#include <cstdlib>
#include <dlfcn.h>

// Advanced TensorFlow model inspection function
void inspectSavedModel(const std::string& modelPath) {
    std::cout << "\n=== Advanced SavedModel Inspection ===" << std::endl;
    std::cout << "Model path: " << modelPath << std::endl;
    
    TF_Status* status = TF_NewStatus();
    TF_SessionOptions* opts = TF_NewSessionOptions();
    
    // Try to load the SavedModel
    TF_Buffer* run_options = TF_NewBuffer();
    TF_Buffer* meta_graph_def = TF_NewBuffer();
    
    const char* tags[] = {"serve"};
    int ntags = 1;
    
    TF_Session* session = TF_LoadSessionFromSavedModel(
        opts, run_options, modelPath.c_str(), tags, ntags,
        nullptr, meta_graph_def, status);
    
    if (TF_GetCode(status) == TF_OK) {
        std::cout << "✓ SavedModel loaded successfully" << std::endl;
        
        // Try to inspect the graph
        TF_Graph* graph = TF_NewGraph();
        TF_ImportGraphDefOptions* import_opts = TF_NewImportGraphDefOptions();
        
        TF_GraphImportGraphDef(graph, meta_graph_def, import_opts, status);
        
        if (TF_GetCode(status) == TF_OK) {
            std::cout << "✓ Graph imported successfully" << std::endl;
            
            // Get operation count
            size_t pos = 0;
            TF_Operation* oper;
            int op_count = 0;
            while ((oper = TF_GraphNextOperation(graph, &pos)) != nullptr) {
                op_count++;
                const char* op_name = TF_OperationName(oper);
                const char* op_type = TF_OperationOpType(oper);
                
                // Print operations that might be inputs/outputs
                std::string name_str(op_name);
                if (name_str.find("serving_default") != std::string::npos ||
                    name_str.find("input") != std::string::npos ||
                    name_str.find("placeholder") != std::string::npos) {
                    std::cout << "Found operation: " << op_name << " (type: " << op_type << ")" << std::endl;
                    
                    // Print output info
                    int num_outputs = TF_OperationNumOutputs(oper);
                    for (int i = 0; i < num_outputs; i++) {
                        TF_Output output = {oper, i};
                        TF_DataType dtype = TF_OperationOutputType(output);
                        std::cout << "  Output " << i << ": dtype=" << dtype << std::endl;
                    }
                }
            }
            std::cout << "Total operations in graph: " << op_count << std::endl;
        } else {
            std::cout << "✗ Failed to import graph: " << TF_Message(status) << std::endl;
        }
        
        TF_DeleteImportGraphDefOptions(import_opts);
        TF_DeleteGraph(graph);
        TF_DeleteSession(session, status);
    } else {
        std::cout << "✗ Failed to load SavedModel: " << TF_Message(status) << std::endl;
    }
    
    // Cleanup
    TF_DeleteBuffer(run_options);
    TF_DeleteBuffer(meta_graph_def);
    TF_DeleteSessionOptions(opts);
    TF_DeleteStatus(status);
    
    std::cout << "=================================" << std::endl;
}

// Debug function to print TensorFlow configuration
void printTensorFlowDebugInfo() {
    std::cout << "=== TensorFlow Debug Information ===" << std::endl;
    std::cout << "TensorFlow version: " << TF_Version() << std::endl;
    
    // Check library loading
    void* handle = dlopen("libtensorflow.so", RTLD_LAZY);
    if (handle) {
        std::cout << "✓ libtensorflow.so loaded successfully" << std::endl;
        dlclose(handle);
    } else {
        std::cout << "✗ Failed to load libtensorflow.so: " << dlerror() << std::endl;
    }
    
    handle = dlopen("libtensorflow_framework.so", RTLD_LAZY);
    if (handle) {
        std::cout << "✓ libtensorflow_framework.so loaded successfully" << std::endl;
        dlclose(handle);
    } else {
        std::cout << "✗ Failed to load libtensorflow_framework.so: " << dlerror() << std::endl;
    }
    
    // Check CUDA libraries
    handle = dlopen("libcudart.so.12", RTLD_LAZY);
    if (handle) {
        std::cout << "✓ libcudart.so.12 available" << std::endl;
        dlclose(handle);
    } else {
        std::cout << "✗ libcudart.so.12 not available: " << dlerror() << std::endl;
    }
    
    handle = dlopen("libcudnn.so", RTLD_LAZY);
    if (handle) {
        std::cout << "✓ libcudnn.so available" << std::endl;
        dlclose(handle);
    } else {
        std::cout << "✗ libcudnn.so not available: " << dlerror() << std::endl;
    }
    
    // Create simple session options to test TensorFlow
    TF_SessionOptions* opts = TF_NewSessionOptions();
    
    if (opts != nullptr) {
        std::cout << "✓ TensorFlow session options created successfully" << std::endl;
    } else {
        std::cout << "✗ Failed to create TensorFlow session options" << std::endl;
    }
    
    // Cleanup
    TF_DeleteSessionOptions(opts);
    
    std::cout << "=================================" << std::endl;
}

// Debug function to check environment variables
void printEnvironmentDebugInfo() {
    std::cout << "=== Environment Debug Information ===" << std::endl;
    
    const char* envVars[] = {
        "CUDA_HOME",
        "CUDA_ROOT", 
        "LD_LIBRARY_PATH",
        "PATH",
        "TF_CPP_MIN_LOG_LEVEL",
        "TF_CPP_MIN_VLOG_LEVEL",
        "CUDA_VISIBLE_DEVICES"
    };
    
    for (const auto& var : envVars) {
        const char* value = std::getenv(var);
        std::cout << var << ": " << (value ? value : "NOT SET") << std::endl;
    }
    
    std::cout << "=====================================" << std::endl;
}

//========================================================================
int main() {
    // Set environment variables to suppress protobuf errors
    setenv("PROTOBUF_INTERNAL_CHECK_DISABLE", "1", 1);
    
    // Force TensorFlow to show all logs for GPU detection
    setenv("TF_CPP_MIN_LOG_LEVEL", "0", 1);
    
    // Print basic debug information (without TensorFlow initialization)
    printEnvironmentDebugInfo();
    
    // Print GPU information
    std::cout << "\n=== GPU Detection ===" << std::endl;
    std::cout << "Checking for NVIDIA GPU..." << std::endl;
    
    // Check NVIDIA GPU availability first
    int gpu_check = system("nvidia-smi > /dev/null 2>&1");
    if (gpu_check != 0) {
        std::cout << "✗ NVIDIA GPU not detected or driver not available!" << std::endl;
        std::cout << "This application requires a NVIDIA GPU with CUDA support." << std::endl;
        std::cout << "Exiting..." << std::endl;
        return EXIT_FAILURE;
    }
    
    std::cout << "✓ NVIDIA GPU detected" << std::endl;
    std::cout << "Starting openFrameworks application..." << std::endl;
    std::cout << "Application will exit if TensorFlow cannot use GPU..." << std::endl;
    
	ofSetupOpenGL(520, 400, OF_WINDOW); // <-------- setup the GL context

	// this kicks off the running of my app
	// can be OF_WINDOW or OF_FULLSCREEN
	// pass in width and height too:
	ofRunApp(new ofApp());
}
