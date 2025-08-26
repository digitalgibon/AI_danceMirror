#pragma once

#include "ofMain.h"
#include <librealsense2/rs.hpp>

#include "ofxTensorFlow2.h"
#include "ofxStyleTransfer.h"

class ofApp : public ofBaseApp{

	public:
		void setup();
		void update();
		void draw();
		void exit();
		
		void keyPressed(int key);
		
	private:
		 rs2::pipeline pipe;
		 rs2::config cfg;
		
		ofTexture colorTex;
		ofTexture depthTex;
		
		int width = 640;
		int height = 480;
		int fps = 30;
		
		bool cameraInitialized = false;

		rs2::points points;
		rs2::pointcloud pc;
		
		ofVboMesh mesh;

			// paths to available style images
		std::vector<std::string> stylePaths = {
			"data/style/picasso.jpeg",
			"data/style/milton.png"
		};
		std::size_t styleIndex = 0; ///< current model path index
		std::string stylePath; ///< current style path

		ofxStyleTransfer styleTransfer; ///< model wrapper
		ofFloatImage imgOut; ///< output image
		bool styleTransferReady = false; ///< is style transfer initialized
		
		// methods
		void setStyle(const std::string& path);
		void nextStyle();

		
};

