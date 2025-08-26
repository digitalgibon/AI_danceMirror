#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
    ofSetWindowTitle("Intel RealSense D435 Test");
    ofSetFrameRate(30);
    
    // Configure streams
    cfg.enable_stream(RS2_STREAM_COLOR, width, height, RS2_FORMAT_RGB8, fps);
    cfg.enable_stream(RS2_STREAM_DEPTH, width, height, RS2_FORMAT_Z16, fps);
    
    // Start pipeline
    try {
        pipe.start(cfg);
        cameraInitialized = true;
        ofLogNotice() << "RealSense D435 started successfully";
    } catch (const rs2::error & e) {
        ofLogError() << "Failed to start RealSense: " << e.what();
        cameraInitialized = false;
    }
    
    // Allocate textures
    colorTex.allocate(width, height, GL_RGB);
    depthTex.allocate(width, height, GL_LUMINANCE);

    // output image
    imgOut.allocate(width, height, OF_IMAGE_COLOR);
    
    ofLogNotice() << "Basic setup completed, TensorFlow disabled for now";

}

//--------------------------------------------------------------
void ofApp::update(){
    if (!cameraInitialized) return;
    
    try {
        // Wait for frames with timeout
        rs2::frameset frames = pipe.wait_for_frames(200);
        
        // Get color frame
        rs2::frame color = frames.get_color_frame();
        if (color) {
            // Create ofPixels from RealSense data
            ofPixels colorPixels;
            colorPixels.setFromPixels((unsigned char*)color.get_data(), width, height, OF_PIXELS_RGB);
            
            // Update texture for display
            colorTex.loadData(colorPixels);
            
            // Process through style transfer
            if(styleTransferReady) {
                styleTransfer.setInput(colorPixels);
            }
        }
        
        // Get depth frame and convert to grayscale
        rs2::depth_frame depth = frames.get_depth_frame();
        if (depth) {
            vector<unsigned char> depthPixels(width * height);
            const uint16_t* depthData = (const uint16_t*)depth.get_data();
            
            for (int i = 0; i < width * height; i++) {
                // Map depth values (0-10m) to grayscale
                depthPixels[i] = ofMap(depthData[i], 0, 10000, 255, 0, true);
            }
            depthTex.loadData(depthPixels.data(), width, height, GL_LUMINANCE);
        }
        
        // Update style transfer
        if(styleTransferReady && styleTransfer.update()) {
            // Style transfer output is ready
            imgOut.setFromPixels(styleTransfer.getOutput().getPixels());
        }
        
    } catch (const rs2::error & e) {
        ofLogError() << "Frame capture error: " << e.what();
    }
}

//--------------------------------------------------------------
void ofApp::draw(){
    ofBackground(20);
    
    if (cameraInitialized) {
        // Draw original color stream
        ofSetColor(255);
        colorTex.draw(0, 0, width/2, height/2);
        
        // Draw depth stream
        depthTex.draw(width/2, 0, width/2, height/2);
        
        // Draw style-transferred output
        if(imgOut.isAllocated()) {
            imgOut.draw(0, height/2, width, height/2);
        }
        
        // Draw labels
        ofSetColor(255);
        ofDrawBitmapStringHighlight("Original", 10, 20, ofColor::black, ofColor::white);
        ofDrawBitmapStringHighlight("Depth", width/2 + 10, 20, ofColor::black, ofColor::white);
        ofDrawBitmapStringHighlight("Style Transfer", 10, height/2 + 20, ofColor::black, ofColor::white);
        ofDrawBitmapStringHighlight("FPS: " + ofToString(ofGetFrameRate(), 1), 10, height - 20, ofColor::black, ofColor::green);
    } else {
        ofSetColor(255, 0, 0);
        ofDrawBitmapString("Camera not initialized!", ofGetWidth()/2 - 100, ofGetHeight()/2);
    }
    
    // Instructions
    ofSetColor(200);
    ofDrawBitmapString("Press 'f' for fullscreen, 's' to change style, 'ESC' to exit", 10, ofGetHeight() - 40);
}

//--------------------------------------------------------------
void ofApp::exit(){
    // Stop style transfer thread
    if(styleTransferReady) {
        styleTransfer.stopThread();
    }
    
    if (cameraInitialized) {
        pipe.stop();
        ofLogNotice() << "RealSense camera stopped";
    }
}

//--------------------------------------------------------------
void ofApp::keyPressed(int key){
    if (key == 'f' || key == 'F') {
        ofToggleFullscreen();
    }
    else if (key == 's' || key == 'S') {
        nextStyle();
    }
}

//--------------------------------------------------------------
void ofApp::setStyle(const std::string& path) {
    stylePath = path;
    ofImage styleImage;
    styleImage.load(stylePath);
    if(styleImage.isAllocated() && styleTransferReady) {
        styleTransfer.setStyle(styleImage.getPixels());
        ofLogNotice() << "Style image loaded: " << stylePath;
    } else {
        ofLogError() << "Failed to load style image: " << stylePath;
    }
}

//--------------------------------------------------------------
void ofApp::nextStyle() {
    styleIndex = (styleIndex + 1) % stylePaths.size();
    setStyle(stylePaths[styleIndex]);
}



