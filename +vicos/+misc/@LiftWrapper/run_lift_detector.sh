#!/bin/bash
#
# A bash wrapper for keypoint and orientation detector part of LIFT

# Bail on error
set -e


# Wrapper-specific variables: input image path, keypoint file and final
# output file are passed via command-line arguments; the rest of optional
# parameters are passed via environment variables
if [[ -z "$1" || -z "$2" || -z "$3" ]]; then
    echo "usage: $0 <input_image> <keypoints_file> <output_file>"
    exit -1
fi

_LIFT_TEST_IMG=$1
_LIFT_KP_FILE_NAME=$2
_LIFT_ORI_FILE_NAME=$3

# Number of keypoints is optionally passed via environment variable
# (leave empty by default!)
#_LIFT_NUM_KEYPOINTS=${_LIFT_NUM_KEYPOINTS:-1000}

# The root path to LIFT code must be passed via _LIFT_BASE_PATH environment
# variable
if [[ -z "$_LIFT_BASE_PATH" ]]; then
    echo "Path to LIFT code must be passed via _LIFT_BASE_PATH variable!"
    exit -1
fi

# Config file and model
_LIFT_TEST_CONFIG="${_LIFT_BASE_PATH}/models/configs/picc-finetune-nopair.config"
_LIFT_MODEL_DIR="${_LIFT_BASE_PATH}/models/picc-best/"


## LIFT settings (taken from the demo script)
# Open MP Settings
export OMP_NUM_THREADS=1

# Cuda Settings
export CUDA_VISIBLE_DEVICES=0

# Theano Flags
export THEANO_FLAGS="device=gpu0,${THEANO_FLAGS}"

## LIFT code settings
# Whether to save debug image for keypoints
_LIFT_SAVE_PNG=0

# Whether the use Theano when keypoint testing. CuDNN is required when turned on
_LIFT_USE_THEANO=0

## Run the programs
_LIFT_PYTHON_CODE_PATH="${_LIFT_BASE_PATH}/python-code"

pushd $_LIFT_PYTHON_CODE_PATH

# Keypoint detector
python compute_detector.py \
	$_LIFT_TEST_CONFIG \
	$_LIFT_TEST_IMG \
	$_LIFT_KP_FILE_NAME \
	$_LIFT_SAVE_PNG \
	$_LIFT_USE_THEANO \
	0 \
	$_LIFT_MODEL_DIR \
	$_LIFT_NUM_KEYPOINTS

# Orientation computation
 python compute_orientation.py \
	$_LIFT_TEST_CONFIG \
	$_LIFT_TEST_IMG \
	$_LIFT_KP_FILE_NAME \
	$_LIFT_ORI_FILE_NAME \
	0 \
	0 \
	$_LIFT_MODEL_DIR

popd
