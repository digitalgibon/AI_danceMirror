/*
 * Adapted from example made with love by Jonathan Frank 2022
 * https://github.com/Jonathhhan
 * Updated by members of the ZKM | Hertz-Lab 2022
 *
 * Originally from ofxTensorFlow2 example_style_transfer_arbitrary under a
 * BSD Simplified License: https://github.com/zkmkarlsruhe/ofxTensorFlow2
 */
#pragma once

#include "ofxTensorFlow2.h"
#include "ofFileUtils.h"

/// \class ofxStyleTransfer
/// \brief wrapper for the arbitrary style transfer model
///
/// the model accepts a style image and applies the style to an input image,
/// the output image will be the same size as the input image
///
/// note: the model requires input input images to be sized in multiples of 32,
///       images are resized between input/output as needed, images must be RGB
///
/// note: input style images are required to 256x256, style images are resized
///       as needed, style images must be RGB
///
/// basic usage example:
///
/// class ofApp : public ofBaseApp {
/// public:
/// ...
///     ofxStyleTransfer styleTransfer;
/// };
///
/// void ofApp::setup() {
///     ...
///     styleTransfer.setup(640, 480, "path/to/modeldir");
///     camera.setup(640, 480);
/// }
///
/// void ofApp.cpp::update() {
///     camera.update();
///     if(camera.isFrameNew()) {
///         styleTransfer.setInput(camera.getPixels());
///     }
///     if(styleTransfer.update()) {
///         ofImage & output = styleTransfer.getOutput();
///         // do something with output
///     }
/// }
///
class ofxStyleTransfer {
	public:

		// model constants
		static const int STYLE_W = 256; ///< style image width expected by the model
		static const int STYLE_H = 256; ///< style image height expected by the model

		/// load and set up style transfer model with input/output image size
		/// returns true on success
		bool setup(int width, int height, const std::string & modelPath="model") {

			// CRITICAL: GPU Memory Setup - Exit if fails
			ofLogNotice("ofxStyleTransfer") << "Setting up GPU memory allocation...";
			if(!ofxTF2::setGPUMaxMemory(ofxTF2::GPU_PERCENT_90, true)) {
				ofLogError("ofxStyleTransfer") << "❌ CRITICAL: Failed to set GPU Memory options!";
				ofLogError("ofxStyleTransfer") << "❌ CRITICAL: GPU acceleration required but not available!";
				ofLogError("ofxStyleTransfer") << "❌ CRITICAL: Exiting application...";
				std::exit(EXIT_FAILURE);
			}
			ofLogNotice("ofxStyleTransfer") << "✓ GPU memory configured for 90% usage";
			
			ofLogNotice("ofxStyleTransfer") << "Loading model from: " << modelPath;
			if(!model.load(modelPath)) {
				ofLogError("ofxStyleTransfer") << "Failed to load model from: " << modelPath;
				return false;
			}
			ofLogNotice("ofxStyleTransfer") << "Model loaded successfully";
			
			// Monitor for GPU device creation messages in TensorFlow logs
			ofLogNotice("ofxStyleTransfer") << "Monitoring TensorFlow for GPU device creation...";
			ofLogNotice("ofxStyleTransfer") << "If you see 'Skipping registering GPU devices' messages, GPU is not working!";
			
			// Try different input name combinations that are commonly used
			// for style transfer models
			std::vector<std::vector<std::string>> inputNameVariants = {
				// Actual tensor names from saved_model_cli inspection
				{"serving_default_placeholder", "serving_default_placeholder_1"},  // content image, style image
				{"serving_default_placeholder_1", "serving_default_placeholder"},  // alternative order
				// Model-specific names (from debug_model.py inspection)
				{"placeholder", "placeholder_1"},  // content image, style image  
				{"placeholder_1", "placeholder"},  // alternative order
				// Common TensorFlow Serving names
				{"serving_default_input_1", "serving_default_input_2"},
				{"serving_default_content_image", "serving_default_style_image"},
				// Alternative naming conventions
				{"input_1", "input_2"},
				{"content_image", "style_image"},
				{"content", "style"}
			};
			
			std::vector<std::string> outputNameVariants = {
				"StatefulPartitionedCall",  // Actual output tensor name from saved_model_cli
				"output_0",  // Model-specific output (from debug_model.py)
				"serving_default_output",
				"output",
				"stylized_image"
			};
			
			bool setupSuccess = false;
			std::string lastError = "";
			
			// Try each combination
			for (const auto& inputNames : inputNameVariants) {
				for (const auto& outputName : outputNameVariants) {
					try {
						ofLogNotice("ofxStyleTransfer") << "Trying input names: " 
							<< inputNames[0] << ", " << inputNames[1] 
							<< " | output: " << outputName;
						
						model.setup(inputNames, {outputName});
						setupSuccess = true;
						
						ofLogNotice("ofxStyleTransfer") << "✓ Successfully configured with inputs: " 
							<< inputNames[0] << ", " << inputNames[1] 
							<< " | output: " << outputName;
						break;
					} catch (const std::exception& e) {
						lastError = e.what();
						ofLogWarning("ofxStyleTransfer") << "✗ Failed with inputs: " 
							<< inputNames[0] << ", " << inputNames[1] 
							<< " | error: " << lastError;
					}
				}
				if (setupSuccess) break;
			}
			
			if (!setupSuccess) {
				ofLogError("ofxStyleTransfer") << "Failed to setup model with any input/output combination. Last error: " << lastError;
				return false;
			}

			// input
			inputVector = {cppflow::tensor(0), cppflow::tensor(0)};
			setSize(width, height);

			// output
			outputImage.allocate(size.width, size.height, OF_IMAGE_COLOR);
			
			ofLogNotice("ofxStyleTransfer") << "✓ Style transfer setup completed with GPU acceleration";
			return true;
		}

		/// clear model
		void clear() {
			model.clear();
		}

		/// set input pixels to process, resizes as needed
		/// image type must be RGB without alpha
		/// note: set the style image before calling this!
		void setInput(const ofPixels & pixels) {
			cppflow::tensor image = pixelsToFloatTensor(pixels);
			if(pixels.getHeight() != modelSize.width || pixels.getWidth() != modelSize.height) {
				image = cppflow::resize_bicubic(image, cppflow::tensor({size.height, size.width}), true);
			}
			inputVector[0] = image;
			newInput = true;
		}

		/// set input style image, resizes as needed
		/// image type must be RGB without alpha
		void setStyle(const ofPixels & pixels) {
			auto style = pixelsToFloatTensor(pixels);
			if(pixels.getHeight() != STYLE_W || pixels.getWidth() != STYLE_H) {
				style = cppflow::resize_bicubic(style, cppflow::tensor({STYLE_H, STYLE_W}), true);
			}
			inputVector[1] = style;
		}

		/// run model on current input, either synchronously by blocking until
		/// finished or asynchronously if background thread is running
		/// returns true if output image is new
		bool update() {
			if(model.isThreadRunning()) {
				// non-blocking
				if(newInput && model.readyForInput()) {
					model.update(inputVector);
					newInput = false;
					inputVector[0] = cppflow::tensor(0); // clear input image
				}
				if(model.isOutputNew()) {
					auto output = model.getOutputs();
					if(sizeChanged) {
						// reallocate for new input size
						outputImage.allocate(size.width, size.height, OF_IMAGE_COLOR);
						sizeChanged = false;
					}
					if(size.width != outputImage.getWidth() ||
					   size.height != outputImage.getHeight()) {
						// change size in next output frame
						sizeChanged = true;
					}
					if(modelSize.width != outputImage.getWidth() ||
					   modelSize.height != outputImage.getHeight()) {
						resizeTensorToImage(output[0], outputImage);
					}
					floatTensorToImage(output[0], outputImage);
					outputImage.update();
					return true;
				}
			}
			else {
				// blocking
				if(newInput) {
					auto output = model.runMultiModel(inputVector);
					if(modelSize.width != outputImage.getWidth() ||
					   modelSize.height != outputImage.getHeight()) {
						resizeTensorToImage(output[0], outputImage);
					}
					floatTensorToImage(output[0], outputImage);
					outputImage.update();
					newInput = false;
					inputVector[0] = cppflow::tensor(0); // clear input image
					return true;
				}
			}
			return false;
		}

		/// get processed output image
		/// note: output size may differ from getWidth() / getHeight() if
		///       setSize() called while model is processing in non-blocking
		///       background thread
		ofImage & getOutput() {
			return outputImage;
		}

		/// draw current output image
		void draw(float x, float y) {
			outputImage.draw(x, y);
		}

		/// draw current output image
		void draw(float x, float y, float w, float h) {
			outputImage.draw(x, y, w, h);
		}

		/// start background thread processing
		void startThread() {
			sizeChanged = false; // reset change detection
			model.startThread();
		}

		/// stop background thread processing
		void stopThread() {
			model.stopThread();
		}

		/// returns true if background thread is running
		bool isThreadRunning() {return model.isThreadRunning();}

		/// returns input width
		/// note: output width may differ if setSize() called while model is
		///       processing in non-blocking background thread, in which case
		///       check the outputImage size
		int getWidth() {return size.width;}

		/// returns input height
		/// note: output height may differ if setSize() called while model is
		///       processing in non-blocking background thread, in which case
		///       check the outputImage size
		int getHeight() {return size.height;}

		/// set new input size
		void setSize(int width, int height) {
			size.width = width;
			size.height = height;
			modelSize.width = ofxStyleTransfer::roundupto(width, 32);
			modelSize.height = ofxStyleTransfer::roundupto(height, 32);
			//if(modelSize.width != width || modelSize.height != height) {
			//	ofLogWarning("ofxStyleTransfer") << width << "x" << height
			//		<< " not multiple(s) of 32, rounding up to "
			//		<< modelSize.width << "x" << modelSize.height;
			//}
			if(model.isThreadRunning() && model.readyForInput()) {
				// resize output image if not processing in background thread
				sizeChanged = true;
			}
		}

		// round n up to nearest multiple, positive only
		static int roundupto(int n, int multiple) {
			return n + multiple - 1 - (n + multiple - 1) % multiple;
		}

	protected:
		ofxTF2::ThreadedModel model;

		// convert ofPixels to a float image tensor
		cppflow::tensor pixelsToFloatTensor(const ofPixels & pixels) {
			// Ensure we have RGB format (3 channels) by creating a copy
			ofPixels rgbPixels;
			if(pixels.getNumChannels() == 4) {
				// Convert RGBA to RGB
				rgbPixels.allocate(pixels.getWidth(), pixels.getHeight(), OF_PIXELS_RGB);
				for(size_t i = 0; i < pixels.getWidth() * pixels.getHeight(); i++) {
					rgbPixels[i*3 + 0] = pixels[i*4 + 0]; // R
					rgbPixels[i*3 + 1] = pixels[i*4 + 1]; // G
					rgbPixels[i*3 + 2] = pixels[i*4 + 2]; // B
					// Skip alpha channel
				}
			} else if(pixels.getNumChannels() == 3) {
				// Already RGB, just copy
				rgbPixels = pixels;
			} else {
				ofLogError("ofxStyleTransfer") << "Unsupported pixel format with " << pixels.getNumChannels() << " channels";
				return cppflow::tensor(0);
			}
			
			auto t = ofxTF2::pixelsToTensor(rgbPixels);
			t = cppflow::expand_dims(t, 0);
			t = cppflow::cast(t, TF_UINT8, TF_FLOAT);
			t = cppflow::mul(t, cppflow::tensor({1.0f / 255.f}));
			return t;
		}

		// convert float image tensor to ofImage
		void floatTensorToImage(cppflow::tensor tensor, ofImage & image) {
			tensor = cppflow::mul(tensor, cppflow::tensor({255.f}));
			tensor = cppflow::cast(tensor, TF_FLOAT, TF_UINT8);
			ofxTF2::tensorToImage(tensor, image);
		}

		// resize tensor to match ofImage
		void resizeTensorToImage(cppflow::tensor & tensor, ofImage & image) {
			tensor = cppflow::resize_bicubic(tensor,
				cppflow::tensor({(int)outputImage.getHeight(),
							     (int)outputImage.getWidth()}), true);
		}

	private:

		struct Size {
			int width = 1;
			int height = 1;
		};
		struct Size size; ///< pixel input (& output) size
		struct Size modelSize; ///< pixel size for the model, multiples of 32
		std::vector<cppflow::tensor> inputVector; // {input image, style image}
		ofImage outputImage; ///< output image
		bool newInput = false; ///< is the input tensor new?

		/// size change between input & output? used when non-blocking only
		bool sizeChanged = false;
};