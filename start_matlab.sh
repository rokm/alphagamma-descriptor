#!/bin/sh

# Matlab
MATLABDIR=/usr/local/MATLAB/R2015b

# OpenCV
OPENCV_LIB=/opt/opencv-3.1.0-descriptor/lib

# Set path
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${OPENCV_LIB}

# Run MATLAB
${MATLABDIR}/bin/matlab
