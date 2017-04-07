@echo off
setlocal

:: Set default CMake generator and architecture: VS2015 Win64
if "%DEFAULT_CMAKE_GENERATOR%"=="" (set "DEFAULT_CMAKE_GENERATOR=Visual Studio 14")
if "%DEFAULT_CMAKE_ARCH%"=="" (set "DEFAULT_CMAKE_ARCH=x64")

echo Using CMake generator: %DEFAULT_CMAKE_GENERATOR%"
echo Using CMake arch: %DEFAULT_CMAKE_ARCH%"
echo.

:: Get the project's root directory (i.e., the location of this script)
set "ROOT_DIR=%~dp0"

:: ########################################################################
:: #                             Build OpenCV                             #
:: ########################################################################
:: NOTE: for the time being, we build and use a private branch of OpenCV
:: with various improvements for integration of descriptors into our
:: evaluation framework.
set "OPENCV_SOURCE_DIR=%ROOT_DIR%\external\opencv"
set "OPENCV_CONTRIB_SOURCE_DIR=%ROOT_DIR%\external\opencv_contrib"
set "OPENCV_BUILD_DIR=%OPENCV_SOURCE_DIR%\build"
set "OPENCV_INSTALL_DIR=%ROOT_DIR%\external\opencv-bin"

echo Building OpenCV...

cmake ^
    -G"%DEFAULT_CMAKE_GENERATOR%" ^
	-A"%DEFAULT_CMAKE_ARCH%" ^
    -H"%OPENCV_SOURCE_DIR%" ^
    -B"%OPENCV_BUILD_DIR%" ^
    -DCMAKE_INSTALL_PREFIX="%OPENCV_INSTALL_DIR%" ^
    -DOPENCV_EXTRA_MODULES_PATH="%OPENCV_CONTRIB_SOURCE_DIR%\modules" ^
    -DCMAKE_SKIP_RPATH=ON ^
    -DWITH_UNICAP=OFF ^
    -DWITH_OPENNI=OFF ^
    -DWITH_TBB=ON ^
    -DWITH_LAPACK=OFF ^
    -DWITH_GDAL=OFF ^
    -DWITH_QT=OFF ^
    -DWITH_GTK=OFF ^
    -DWITH_OPENGL=OFF ^
    -DWITH_CUDA=OFF ^
    -DWITH_OPENCL=OFF ^
    -DWITH_GPHOTO2=OFF ^
    ^
    -DBUILD_opencv_java=OFF ^
    -DBUILD_opencv_python2=OFF ^
    -DBUILD_opencv_python3=OFF ^
    ^
    -DBUILD_opencv_ts=OFF ^
    -DBUILD_opencv_viz=OFF ^
    ^
    -DBUILD_opencv_aruco=OFF ^
    -DBUILD_opencv_bgsegm=OFF ^
    -DBUILD_opencv_bioinspired=OFF ^
    -DBUILD_opencv_ccalib=OFF ^
    -DBUILD_opencv_contrib_world=OFF ^
    -DBUILD_opencv_cvv=OFF ^
    -DBUILD_opencv_datasets=OFF ^
    -DBUILD_opencv_dnn=OFF ^
    -DBUILD_opencv_dpm=OFF ^
    -DBUILD_opencv_face=OFF ^
    -DBUILD_opencv_fuzzy=OFF ^
    -DBUILD_opencv_hdf=OFF ^
    -DBUILD_opencv_line_descriptor=OFF ^
    -DBUILD_opencv_matlab=OFF ^
    -DBUILD_opencv_optflow=OFF ^
    -DBUILD_opencv_reg=OFF ^
    -DBUILD_opencv_rgbd=OFF ^
    -DBUILD_opencv_saliency=OFF ^
    -DBUILD_opencv_sfm=OFF ^
    -DBUILD_opencv_stereo=OFF ^
    -DBUILD_opencv_structured_light=OFF ^
    -DBUILD_opencv_surface_matching=OFF ^
    -DBUILD_opencv_text=OFF ^
    -DBUILD_opencv_tracking=OFF ^
    -DBUILD_opencv_ximgproc=OFF ^
    -DBUILD_opencv_xobjdetect=OFF ^
    -DBUILD_opencv_xphoto=OFF
if %errorlevel% neq 0 (
	echo OpenCV configuration failed!
	exit /b %errorlevel%
)

cmake --build "%OPENCV_BUILD_DIR%" --target ALL_BUILD --config Release
if %errorlevel% neq 0 exit /b %errorlevel%

cmake --build "%OPENCV_BUILD_DIR%" --target INSTALL --config Release
if %errorlevel% neq 0 exit /b %errorlevel%

:: Build mexopencv
echo Building mexopencv...

set "MEXOPENCV_DIR=%ROOT_DIR%\external\mexopencv"
matlab -nodisplay -nodesktop -nosplash -minimize -wait -r "try, addpath('%MEXOPENCV_DIR%'); mexopencv.make('opencv_path', '%OPENCV_INSTALL_DIR%', 'progress', true); catch e, exit(-1); end; exit(0);"
if %errorlevel% neq 0 exit /b %errorlevel%

:: Build Matlab/MEX dependencies
echo Building MEX files...

matlab -nodisplay -nodesktop -nosplash -minimize -wait -r "try, run('%ROOT_DIR%\compile_code.m'); catch e, exit(-1); end; exit(0);"
if %errorlevel% neq 0 exit /b %errorlevel%

:: End of script
echo Great success! Build script finished without errors!

endlocal
