# make sure the the OF_ROOT location is defined
ifndef OF_ROOT
	OF_ROOT=$(realpath ../../..)
endif

# Include project config first so its PROJECT_* vars are visible to the build system
ifneq ($(wildcard config.make),)
	include config.make
endif

# Addon (TensorFlow) targets before core compile (so their flags are merged)
include $(OF_ROOT)/addons/ofxTensorFlow2/addon_targets.mk

# Now include the core openFrameworks build rules (will pick up -lrealsense2 already)
include $(OF_ROOT)/libs/openFrameworksCompiled/project/makefileCommon/compile.project.mk
include $(OF_ROOT)/addons/ofxTensorFlow2/addon_targets.mk

# Add RealSense library manually to PROJECT_LDFLAGS
PROJECT_LDFLAGS += -lrealsense2
