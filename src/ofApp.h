/*
 * Example made with love by Jonathan Frank 2022
 * https://github.com/Jonathhhan
 * Updated by members of the ZKM | Hertz-Lab 2022
 */
#pragma once

#include "ofMain.h"
#include "ofxTensorFlow2.h"
#include "ofxStyleTransfer.h"
#include <librealsense2/rs.hpp>

// use RealSense camera for live input
#define USE_REALSENSE_CAMERA

class ofApp : public ofBaseApp {

	public:
		void setup();
		void update();
		void draw();
		void exit();

		void keyPressed(int key);
		void keyReleased(int key);
		void mouseMoved(int x, int y);
		void mouseDragged(int x, int y, int button);
		void mousePressed(int x, int y, int button);
		void mouseReleased(int x, int y, int button);
		void mouseEntered(int x, int y);
		void mouseExited(int x, int y);
		void windowResized(int w, int h);
		void dragEvent(ofDragInfo dragInfo);
		void gotMessage(ofMessage msg);

		/// goto prev style in the stylePaths vector
		void prevStyle();

		/// goto next style in the stylePaths vector
		void nextStyle();

		/// set style from given input image
		void setStyle(std::string & path);
		
		/// reprocess the input image with current style
		void reprocessImage();

		ofxStyleTransfer styleTransfer; ///< model wrapper
		ofFloatImage imgOut; ///< output image

		// RealSense camera
		#ifdef USE_REALSENSE_CAMERA
			rs2::pipeline pipe;
			rs2::config cfg;
			ofTexture colorTex;
			ofImage colorImage;
			int cameraWidth = 640;
			int cameraHeight = 480;
			int fps = 30;
			bool cameraInitialized = false;
		#endif

		// image input & output size
		const static int imageWidth = 640;  // Match camera resolution
		const static int imageHeight = 480; // Match camera resolution

		// paths to available style images
		std::vector<std::string> stylePaths = {
			"style/milton.png",
			"style/picasso.jpeg",
			"style/mama.jpg"
		};
		std::size_t styleIndex = 0; ///< current model path index
};