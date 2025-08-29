#include "ofMain.h"
#include "ofApp.h"
#include "tensorflow/c/c_api.h"

//========================================================================
int main() {
	std::cout << "TensorFlow version: " << TF_Version() << std::endl;
	ofSetupOpenGL(520, 400, OF_WINDOW); // <-------- setup the GL context

	// this kicks off the running of my app
	// can be OF_WINDOW or OF_FULLSCREEN
	// pass in width and height too:
	ofRunApp(new ofApp());
}
