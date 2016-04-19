#!/bin/sh

# Matlab
MATLABDIR=/usr/local/MATLAB/R2015b

# OpenCV
OPENCV_LIB=$(pwd)/external/opencv-bin/lib/

# Set path
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${OPENCV_LIB}

# Run MATLAB
${MATLABDIR}/bin/matlab
