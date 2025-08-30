/*
 * Example made with love by Jonathan Frank 2022
 * https://github.com/Jonathhhan
 * Updated by members of the ZKM | Hertz-Lab 2022
 */
#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup() {
	ofSetFrameRate(60);
	ofSetVerticalSync(true);
	ofSetWindowTitle("AI Dance Mirror - RealSense Style Transfer");

	// ofxTF2 setup
	if(!ofxTF2::setGPUMaxMemory(ofxTF2::GPU_PERCENT_50, true)) {
		ofLogError() << "failed to set GPU Memory options!";
	}

	// load model
	if(!styleTransfer.setup(imageWidth, imageHeight, "models/my_model")) {
		std::exit(EXIT_FAILURE);
	}
	
	#ifdef USE_REALSENSE_CAMERA
	// Configure RealSense streams
	cfg.enable_stream(RS2_STREAM_COLOR, cameraWidth, cameraHeight, RS2_FORMAT_RGB8, fps);
	
	// Start RealSense pipeline
	try {
		pipe.start(cfg);
		cameraInitialized = true;
		ofLogNotice() << "RealSense D435 started successfully";
		
		// Allocate textures and images
		colorTex.allocate(cameraWidth, cameraHeight, GL_RGB);
		colorImage.allocate(cameraWidth, cameraHeight, OF_IMAGE_COLOR);
		
	} catch (const rs2::error & e) {
		ofLogError() << "Failed to start RealSense: " << e.what();
		cameraInitialized = false;
		std::exit(EXIT_FAILURE);
	}
	#endif
	
	// set initial style
	setStyle(stylePaths[styleIndex]);
	
	// start processing thread
	styleTransfer.startThread();

	// output image
	imgOut.allocate(imageWidth, imageHeight, OF_IMAGE_COLOR);
}

//--------------------------------------------------------------
void ofApp::update() {
	#ifdef USE_REALSENSE_CAMERA
	if (!cameraInitialized) return;
	
	try {
		// Wait for frames with timeout
		rs2::frameset frames = pipe.wait_for_frames(1000);
		
		// Get color frame
		rs2::frame color = frames.get_color_frame();
		if (color) {
			// Load data into texture for display
			colorTex.loadData((unsigned char*)color.get_data(), cameraWidth, cameraHeight, GL_RGB);
			
			// Update color image for style transfer processing
			colorImage.setFromPixels((unsigned char*)color.get_data(), cameraWidth, cameraHeight, OF_IMAGE_COLOR);
			
			// Set input for style transfer
			styleTransfer.setInput(colorImage.getPixels());
		}
		
	} catch (const rs2::error & e) {
		ofLogError() << "Frame capture error: " << e.what();
	}
	#endif
	
	// check if style transfer processing is complete
	if(styleTransfer.update()) {
		imgOut = styleTransfer.getOutput();
		imgOut.update();
		ofLog() << "Style transfer completed!";
	}
}

//--------------------------------------------------------------
void ofApp::draw() {
	ofBackground(20);
	
	#ifdef USE_REALSENSE_CAMERA
	if (cameraInitialized) {
		// Draw original camera feed on the left
		ofSetColor(255);
		colorTex.draw(0, 0, 320, 240);
		
		// Draw style-transferred output on the right
		imgOut.draw(340, 0, 320, 240);
		
		// Draw labels
		ofSetColor(255);
		ofDrawBitmapStringHighlight("Camera Input", 10, 20, ofColor::black, ofColor::white);
		ofDrawBitmapStringHighlight("Style Transfer Output", 350, 20, ofColor::black, ofColor::white);
		ofDrawBitmapStringHighlight("Current style: " + ofFilePath::getFileName(stylePaths[styleIndex]), 10, 260, ofColor::black, ofColor::green);
		ofDrawBitmapStringHighlight("FPS: " + ofToString(ofGetFrameRate(), 1), 10, 280, ofColor::black, ofColor::green);
	} else {
		ofSetColor(255, 0, 0);
		ofDrawBitmapString("Camera not initialized!", ofGetWidth()/2 - 100, ofGetHeight()/2);
	}
	#else
	// draw the output image (fallback for non-camera mode)
	imgOut.draw(20, 20, 320, 240);
	#endif
	
	// Instructions
	ofSetColor(200);
	ofDrawBitmapString("LEFT/RIGHT arrows: change style, 'f': fullscreen, 'ESC': exit", 10, ofGetHeight() - 20);
}

//--------------------------------------------------------------
void ofApp::keyPressed(int key) {
	switch(key) {
		case OF_KEY_LEFT:
			prevStyle();
			break;
		case OF_KEY_RIGHT:
			nextStyle();
			break;
		case 'f':
		case 'F':
			ofToggleFullscreen();
			break;
		case 'r':
		case 'R':
			// reprocess current camera frame with current style
			ofLog() << "Reprocessing current frame...";
			break;
		default: break;
	}
}

//--------------------------------------------------------------
void ofApp::keyReleased(int key) {

}

//--------------------------------------------------------------
void ofApp::mouseMoved(int x, int y) {

}

//--------------------------------------------------------------
void ofApp::mouseDragged(int x, int y, int button) {

}

//--------------------------------------------------------------
void ofApp::mousePressed(int x, int y, int button) {

}

//--------------------------------------------------------------
void ofApp::mouseReleased(int x, int y, int button) {

}

//--------------------------------------------------------------
void ofApp::mouseEntered(int x, int y) {

}

//--------------------------------------------------------------
void ofApp::mouseExited(int x, int y) {

}

//--------------------------------------------------------------
void ofApp::windowResized(int w, int h) {

}

//--------------------------------------------------------------
void ofApp::dragEvent(ofDragInfo dragInfo) {

}

//--------------------------------------------------------------
void ofApp::gotMessage(ofMessage msg) {

}

//--------------------------------------------------------------
void ofApp::prevStyle() {
	if(styleIndex == 0) {
		styleIndex = stylePaths.size()-1;
	}
	else {
		styleIndex--;
	}
	setStyle(stylePaths[styleIndex]);
	reprocessImage();
}

//--------------------------------------------------------------
void ofApp::nextStyle() {
	styleIndex++;
	if(styleIndex >= stylePaths.size()) {
		styleIndex = 0;
	}
	setStyle(stylePaths[styleIndex]);
	reprocessImage();
}

//--------------------------------------------------------------
void ofApp::setStyle(std::string & path) {
	ofImage styleImg;
	styleImg.setUseTexture(false); // We don't need texture for processing
	if(!styleImg.load(path)) {
		ofLogError() << "Failed to load style image: " << path;
		return;
	}
	// Ensure RGB format
	if(styleImg.getPixels().getNumChannels() != 3) {
		styleImg.getPixels().setImageType(OF_IMAGE_COLOR);
	}
	styleTransfer.setStyle(styleImg.getPixels());
	ofLog() << "Style changed to: " << ofFilePath::getFileName(path) << " (" << styleImg.getPixels().getNumChannels() << " channels)";
}

//--------------------------------------------------------------
void ofApp::reprocessImage() {
	#ifdef USE_REALSENSE_CAMERA
	// With camera input, we don't need to reload anything
	// The current frame will be processed with the new style automatically
	ofLog() << "Style changed, processing will continue with new style on next frame";
	#else
	// reload and reprocess the input image with current style (fallback)
	ofImage inputImage;
	inputImage.setUseTexture(false); // We don't need texture for processing
	if(inputImage.load("promyczek.jpg")) {
		// Ensure RGB format
		if(inputImage.getPixels().getNumChannels() != 3) {
			inputImage.getPixels().setImageType(OF_IMAGE_COLOR);
		}
		styleTransfer.setInput(inputImage.getPixels());
		ofLog() << "Reprocessing image with current style...";
	}
	#endif
}

//--------------------------------------------------------------
void ofApp::exit() {
	#ifdef USE_REALSENSE_CAMERA
	if (cameraInitialized) {
		pipe.stop();
		ofLogNotice() << "RealSense camera stopped";
	}
	#endif
	
	// Stop style transfer thread
	styleTransfer.stopThread();
}