#!/bin/bash

# Matlab directory; set only if not already set
MATLABDIR=${MATLABDIR:-/usr/local/MATLAB/R2016b}

# Get the project's root directory (i.e., the location of this script)
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Quit on error
set -e


# OpenCV
OPENCV_LIB="${ROOT_DIR}/external/opencv-bin/lib/"
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${OPENCV_LIB}


# Run MATLAB
${MATLABDIR}/bin/matlab -r "run ${ROOT_DIR}/startup.m"
