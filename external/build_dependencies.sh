#!/bin/sh

MATLABDIR=/usr/local/MATLAB/R2015a

EXTERNAL_ROOT=$(pwd)


########################################################################
#                             Build OpenCV                             #
########################################################################
pushd opencv

mkdir build
pushd build

cmake \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX=${EXTERNAL_ROOT}/opencv-bin \
    -DOPENCV_EXTRA_MODULES_PATH=${EXTERNAL_ROOT}/opencv_contrib/modules \
    -DCMAKE_SKIP_RPATH=ON \
    -DWITH_UNICAP=OFF \
    -DWITH_OPENNI=OFF \
    -DWITH_TBB=ON \
    -DWITH_GDAL=OFF \
    -DWITH_QT=OFF \
    -DWITH_GTK=OFF \
    -DWITH_OPENGL=OFF \
    -DWITH_CUDA=OFF \
    -DWITH_OPENCL=OFF \
    -DWITH_GPHOTO2=OFF \
    \
    -DBUILD_opencv_java=OFF \
    -DBUILD_opencv_python2=OFF \
    -DBUILD_opencv_python3=OFF \
    \
    -DBUILD_opencv_ts=OFF \
    -DBUILD_opencv_viz=OFF \
    \
    -DBUILD_opencv_aruco=OFF \
    -DBUILD_opencv_bgsegm=OFF \
    -DBUILD_opencv_bioinspired=OFF \
    -DBUILD_opencv_ccalib=OFF \
    -DBUILD_opencv_contrib_world=OFF \
    -DBUILD_opencv_cvv=OFF \
    -DBUILD_opencv_datasets=OFF \
    -DBUILD_opencv_dnn=OFF \
    -DBUILD_opencv_dpm=OFF \
    -DBUILD_opencv_face=OFF \
    -DBUILD_opencv_fuzzy=OFF \
    -DBUILD_opencv_hdf=OFF \
    -DBUILD_opencv_line_descriptor=OFF \
    -DBUILD_opencv_matlab=OFF \
    -DBUILD_opencv_optflow=OFF \
    -DBUILD_opencv_reg=OFF \
    -DBUILD_opencv_rgbd=OFF \
    -DBUILD_opencv_saliency=OFF \
    -DBUILD_opencv_sfm=OFF \
    -DBUILD_opencv_stereo=OFF \
    -DBUILD_opencv_structured_light=OFF \
    -DBUILD_opencv_surface_matching=OFF \
    -DBUILD_opencv_text=OFF \
    -DBUILD_opencv_tracking=OFF \
    -DBUILD_opencv_ximgproc=OFF \
    -DBUILD_opencv_xobjdetect=OFF \
    -DBUILD_opencv_xphoto=OFF \
    ..

make -j4
make install

popd
popd


########################################################################
#                            Build mexopencv                           #
########################################################################
export PKG_CONFIG_PATH=${EXTERNAL_ROOT}/opencv-bin/lib/pkgconfig:${PKG_CONFIG_PATH}

pushd mexopencv
make -j4 MATLABDIR=${MATLABDIR}
popd
