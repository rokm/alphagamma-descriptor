#!/bin/bash

# Matlab directory; set only if not already set
MATLABDIR=${MATLABDIR:-/usr/local/MATLAB/R2016b}

# Get the project's root directory (i.e., the location of this script)
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


# Quit on error
set -e

########################################################################
#                             Build OpenCV                             #
########################################################################
# NOTE: for the time being, we build and use a private branch of OpenCV
# with various improvements for integration of descriptors into our
# evaluation framework.
#
# Fedora dependencies:
#  libtiff-devel libjpeg-devel libwebp-devel jasper-devel OpenEXR-devel
#  ffmpeg-devel
#  eigen3-devel tbb-devel openblas-devel

echo "Building OpenCV..."

OPENCV_SOURCE_DIR="${ROOT_DIR}/external/opencv"
OPENCV_CONTRIB_SOURCE_DIR="${ROOT_DIR}/external/opencv_contrib"
OPENCV_BUILD_DIR="${OPENCV_SOURCE_DIR}/build"
OPENCV_INSTALL_DIR="${ROOT_DIR}/external/opencv-bin"

# Make sure the submodule has been checked out
if [ ! -f "${OPENCV_SOURCE_DIR}/.git" ]; then
    echo "The opencv submodule does not appear to be checked out!"
    exit 1
fi

# Build and install
mkdir -p "${OPENCV_BUILD_DIR}"

cmake \
    -H"${OPENCV_SOURCE_DIR}" \
    -B"${OPENCV_BUILD_DIR}" \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX="${OPENCV_INSTALL_DIR}" \
    -DOPENCV_EXTRA_MODULES_PATH="${OPENCV_CONTRIB_SOURCE_DIR}/modules" \
    -DCMAKE_SKIP_RPATH=ON \
    -DWITH_UNICAP=OFF \
    -DWITH_OPENNI=OFF \
    -DWITH_TBB=ON \
    -DWITH_LAPACK=OFF \
    -DWITH_GDAL=OFF \
    -DWITH_QT=OFF \
    -DWITH_GTK=OFF \
    -DWITH_OPENGL=OFF \
    -DWITH_CUDA=OFF \
    -DWITH_OPENCL=OFF \
    -DWITH_GPHOTO2=OFF \
    \
    -DBUILD_opencv_apps=OFF \
    -DBUILD_opencv_calib3d=ON \
    -DBUILD_opencv_core=ON \
    -DBUILD_opencv_cudaarithm=OFF \
    -DBUILD_opencv_cudabgsegm=OFF \
    -DBUILD_opencv_cudacodec=OFF \
    -DBUILD_opencv_cudafeatures2d=OFF \
    -DBUILD_opencv_cudafilters=OFF \
    -DBUILD_opencv_cudaimgproc=OFF \
    -DBUILD_opencv_cudalegacy=OFF \
    -DBUILD_opencv_cudaobjdetect=OFF \
    -DBUILD_opencv_cudaoptflow=OFF \
    -DBUILD_opencv_cudastereo=OFF \
    -DBUILD_opencv_cudawarping=OFF \
    -DBUILD_opencv_cudev=OFF \
    -DBUILD_opencv_dnn=ON \
    -DBUILD_opencv_features2d=ON \
    -DBUILD_opencv_flann=ON \
    -DBUILD_opencv_highgui=ON \
    -DBUILD_opencv_imgcodecs=ON \
    -DBUILD_opencv_imgproc=ON \
    -DBUILD_opencv_java=OFF \
    -DBUILD_opencv_ml=ON \
    -DBUILD_opencv_objdetect=ON \
    -DBUILD_opencv_photo=ON \
    -DBUILD_opencv_python2=OFF \
    -DBUILD_opencv_python3=OFF \
    -DBUILD_opencv_shape=ON \
    -DBUILD_opencv_stitching=ON \
    -DBUILD_opencv_superres=ON \
    -DBUILD_opencv_ts=OFF \
    -DBUILD_opencv_video=ON \
    -DBUILD_opencv_videoio=ON \
    -DBUILD_opencv_videostab=ON \
    -DBUILD_opencv_viz=OFF \
    -DBUILD_opencv_world=OFF \
    \
    -DBUILD_opencv_aruco=ON \
    -DBUILD_opencv_bgsegm=ON \
    -DBUILD_opencv_bioinspired=ON \
    -DBUILD_opencv_ccalib=OFF \
    -DBUILD_opencv_cnn_3dobj=OFF \
    -DBUILD_opencv_contrib_world=OFF \
    -DBUILD_opencv_cvv=OFF \
    -DBUILD_opencv_datasets=ON \
    -DBUILD_opencv_dnn_modern=OFF \
    -DBUILD_opencv_dnns_easily_fooled=OFF \
    -DBUILD_opencv_dpm=ON \
    -DBUILD_opencv_face=ON \
    -DBUILD_opencv_freetype=OFF \
    -DBUILD_opencv_fuzzy=OFF \
    -DBUILD_opencv_hdf=OFF \
    -DBUILD_opencv_img_hash=ON \
    -DBUILD_opencv_line_descriptor=ON \
    -DBUILD_opencv_matlab=OFF \
    -DBUILD_opencv_optflow=ON \
    -DBUILD_opencv_phase_unwrapping=OFF \
    -DBUILD_opencv_plot=ON \
    -DBUILD_opencv_reg=OFF \
    -DBUILD_opencv_rgbd=OFF \
    -DBUILD_opencv_saliency=ON \
    -DBUILD_opencv_sfm=OFF \
    -DBUILD_opencv_stereo=OFF \
    -DBUILD_opencv_structured_light=OFF \
    -DBUILD_opencv_surface_matching=OFF \
    -DBUILD_opencv_text=ON \
    -DBUILD_opencv_tracking=ON \
    -DBUILD_opencv_xfeatures2d=ON \
    -DBUILD_opencv_ximgproc=ON \
    -DBUILD_opencv_xobjdetect=ON \
    -DBUILD_opencv_xphoto=ON

make -j4 -C "${OPENCV_BUILD_DIR}"
make install -C "${OPENCV_BUILD_DIR}"


########################################################################
#                            Build mexopencv                           #
########################################################################
echo "Building mexopencv..."
export PKG_CONFIG_PATH=${OPENCV_INSTALL_DIR}/lib64/pkgconfig:${PKG_CONFIG_PATH}

make -j4 MATLABDIR="${MATLABDIR}" -C "${ROOT_DIR}/external/mexopencv"


########################################################################
#                    Build Matlab/MEX dependencies                     #
########################################################################
# This could have been done from inside Matlab, but it is more convenient
# to keep it inside a single script
echo "Building Mex files..."
${MATLABDIR}/bin/matlab -nodisplay -nodesktop -r "try, run('${ROOT_DIR}/compile_code.m'); catch e, exit(-1); end; exit(0);"


########################################################################
#                        Build LIFT dependencies                       #
########################################################################
echo "Building LIFT..."

LIFT_SOURCE_DIR="${ROOT_DIR}/external/lift/c-code"
LIFT_BUILD_DIR="${LIFT_SOURCE_DIR}/build"

# Build
cmake \
    -H"${LIFT_SOURCE_DIR}" \
    -B"${LIFT_BUILD_DIR}" \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX="${OPENCV_INSTALL_DIR}" \
    -DOpenCV_DIR="${OPENCV_INSTALL_DIR}/share/OpenCV"

make -C "${LIFT_BUILD_DIR}"


########################################################################
#                         Build Caffe for TFeat                        #
########################################################################
echo "Building Caffe..."

CAFFE_SOURCE_DIR="${ROOT_DIR}/external/caffe"
CAFFE_BUILD_DIR="${CAFFE_SOURCE_DIR}/build"
CAFFE_INSTALL_DIR="${ROOT_DIR}/external/caffe-bin"

# Make sure the submodule has been checked out
if [ ! -f "${CAFFE_SOURCE_DIR}/.git" ]; then
    echo "The caffe submodule does not appear to be checked out!"
    exit 1
fi

# Build and install
mkdir -p "${CAFFE_BUILD_DIR}"

cmake \
    -H"${CAFFE_SOURCE_DIR}" \
    -B"${CAFFE_BUILD_DIR}" \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX="${CAFFE_INSTALL_DIR}" \
    -DBLAS=open \
    -DUSE_OPENCV=OFF \
    -DCUDA_ARCH_NAME="Pascal" \
    -DCUDA_HOST_COMPILER=/usr/bin/cuda-g++ \
    -DBUILD_matlab=ON \
    -DMatlab_DIR=${MATLABDIR}


make -j4 -C "${CAFFE_BUILD_DIR}"
make install -C "${CAFFE_BUILD_DIR}"



# End of script
echo "Great success! Build script finished without errors!"
