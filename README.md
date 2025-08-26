# AI Dance Mirror

A real-time style transfer application using Intel RealSense D435 camera and TensorFlow2, built with openFrameworks.

## Features

- Real-time RGB and depth capture from Intel RealSense D435
- AI-powered style transfer using arbitrary image stylization
- Multiple style presets with ability to switch styles on-the-fly
- Real-time processing with threaded TensorFlow inference

## Requirements

### Hardware
- Intel RealSense D435 camera
- NVIDIA GPU (recommended for real-time performance)

### Software
- openFrameworks 0.11.2+
- Intel RealSense SDK 2.0
- TensorFlow 2.x
- ofxTensorFlow2 addon
- librealsense2

## Installation

1. Clone this repository to your openFrameworks apps folder:
   ```bash
   cd /path/to/openFrameworks/apps/myApps/
   git clone https://github.com/yourusername/AI_danceMirror.git
   ```

2. Install dependencies:
   ```bash
   # Install RealSense SDK
   sudo apt install librealsense2-dev librealsense2-utils
   
   # Install TensorFlow C++ library (if not already installed)
   ```

3. Download the TensorFlow style transfer model:
   ```bash
   cd AI_danceMirror/bin/data/
   # Model should be placed in data/model/ directory
   ```

4. Build and run:
   ```bash
   cd AI_danceMirror
   make -j4
   make run
   ```

## Usage

- Press 'f' to toggle fullscreen
- Press 's' to cycle through available styles
- Press 'ESC' to exit

## Project Structure

```
AI_danceMirror/
├── src/
│   ├── main.cpp
│   ├── ofApp.cpp
│   ├── ofApp.h
│   └── ofxStyleTransfer.h
├── bin/
│   └── data/
│       ├── model/          # TensorFlow model files
│       └── style/          # Style images
├── config.make
├── addons.make
└── Makefile
```

## Dependencies (addons.make)

```
ofxTensorFlow2
```

## Technical Details

- Input resolution: 640x480 @ 30fps
- Style transfer model: Arbitrary Image Stylization v1-256
- Real-time processing with background threading
- Automatic image resizing for model compatibility

## License

[Add your license here]

## Contributing

[Add contributing guidelines here]
