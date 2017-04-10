# AlphaGamma keypoint descriptor #

**Prototype & evaluation framework**

(C) 2015-2017, Rok Mandeljc


## Summary

This project contains the prototype implementation of the AlphaGamma
keypoint descriptor, presented in:

1. R. Mandeljc, D. Skočaj, and J. Maver, AGs: local descriptors based on
dependent effects model, submitted to TPAMI


The code is provided as supplement to the TPAMI submission [1], and
provides reference/prototype implementation of the AlphaGamma descriptor,
as well as the RADIAL keypoint detector. In addition, experimental
framework and scripts for reproducing the experimental results from
the paper are provided.

The sections below outline the installation and setup, basic use of the
code, and steps needed to reproduce the experiments.

*Note:* the majority of instructions are linux-centric (i.e., most of
the listed command-line steps are written for linux shell).


## Prerequisites

The code was primarily developed on linux (Fedora 24/25) with Matlab
R2016b, but has also been tested on Windows with Visual Studio 2015 and
Matlab R2016a.

The code makes use of OpenCV via mexopencv. For the sake of consistency,
all the requirements are bundled with the code by means of git submodules.
For OpenCV, we build and locally install a checkout from a custom branch
that contains couple of fixes needed for consistent descriptor evaluation.

### Linux

Recent 64-bit linux distribution with basic compilation toolchain
(git, gcc, CMake, make). In addition, dependencies for building the git
checkout of OpenCV are required. On Fedora, the basic set of development
libraries I use can be installed via:
```Shell
sudo dnf install git cmake gcc-c++ \
    libtiff-devel libjpeg-devel libwebp-devel jasper-devel OpenEXR-devel \
    ffmpeg-devel \
    eigen3-devel tbb-devel openblas-devel
```

Recent Matlab with Image processing toolbox and working MEX compiler.

### Windows

The code was tested using 64-bit Windows 8.1 and Visual Studio 2015.

A recent Matlab with Image processing toolbox and working MEX compiler
is required. Make sure that Matlab executable is in PATH; i.e., that you
can start it by running ```matlab``` from Windows command prompt (cmd).

In addition, you will need git and CMake. Make sure that the path to
CMake executable is in PATH.

Ensure that MEX compiler is properly set up in Matlab, and that it
points to the correct Visual Studio installation. You can check this
by running the following inside Matlab:
```Matlab
mex -setup C++
```
and following its instructions for choosing the correct compiler.


## Installation

Create a working directory and move inside it, e.g.:
```Shell
mkdir alphagamma-descriptor
cd alphagamma-descriptor
```
This directory will contain the checkout of code, as well as datasets,
if you wish to replicate the results from the paper. By default, the code
makes certain assumptions about locations of the dataset images that are
tied to the described structure of the working directory. Unless stated
otherwise, the rest of instructions assumes that commands are run from
this directory (both shell and Matlab).

Checkout the code from git repository into "code" subdirectory:
```Shell
git clone https://github.com/rokm/alphagamma-descriptor code
cd code
git submodule update --init --recursive
cd ..
```
The above command should also pull in all external dependencies from
their corresponding repositories.

If you wish to use our evaluation framework to replicate the results
from paper, follow to the next subsection to install the datasets. If you
wish to just use the keypoint detectors and descriptors, you can skip the
following subsection and proceed to the installation instructions for your
platform.

### Installing datasets

The evaluation code assumes that the datasets are located inside ```datasets```
subfolder inside your working directory. Therefore, create the datasets
directory, and move inside it.
```Shell
mkdir datasets
cd datasets
```

#### Oxford Affine dataset

The Oxford dataset sequences are available here: http://www.robots.ox.ac.uk/~vgg/research/affine

Inside the ```datasets``` directory, create a directory called ```affine```.
Inside this directory, download the sequences and unpack them to their
corresponding directories:
```Shell
mkdir affine
cd affine

wget http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/bikes.tar.gz
mkdir bikes
tar xvzf bikes.tar.gz -C bikes

wget http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/trees.tar.gz
mkdir trees
tar xvzf trees.tar.gz -C trees

wget http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/graf.tar.gz
mkdir graffiti
tar xvzf graf.tar.gz -C graffiti

wget http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/wall.tar.gz
mkdir wall
tar xvzf wall.tar.gz -C wall

http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/bark.tar.gz
mkdir bark
tar xvzf bark.tar.gz -C bark

http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/boat.tar.gz
mkdir boat
tar xvzf boat.tar.gz -C boat

http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/leuven.tar.gz
mkdir leuven
tar xvzf leuven.tar.gz -C leuven

http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/ubc.tar.gz
mkdir ubc
tar xvzf ubc.tar.gz -C ubc

rm -f *.tar.gz
cd ..
```

#### DTU dataset

The DTU Point Feature Data Set is avaiable here: http://roboimagedata.compute.dtu.dk/?page_id=24

Inside the ```datasets``` directory, create a directory called ```dtu_robot```,
into which we will unpack the required parts of the dataset.
```Shell
mkdir dtu_robot
cd dtu_robot
```

First, download calibration file and rename it to ```Calib_Results_11.mat```:
```Shell
wget http://roboimagedata.imm.dtu.dk/data/calibration/calibrationFile.mat
mv calibrationFile.mat Calib_Results_11.mat
```

Download 3-D reconstruction data and unpack it into ```CleanRecon_2009_11_16``` directory:
```Shell
wget http://roboimagedata.imm.dtu.dk/data/3D_reconstructions/reconstructions.zip
unzip reconstructions.zip -d CleanRecon_2009_11_16
```

The above two steps can be replaced by downloading the whole evaluation
code package from http://roboimagedata.imm.dtu.dk/code/RobotEvalCode.tar.gz
and extracting the afore-mentioned ```Calib_Results_11.mat``` file and
```CleanRecon_2009_11_16``` directory into current (```dtu_robot``` directory).

Afterwards, download and extract the sequence data (we are using the
half-sized images), and extract them directly into current directory.
Even the half-sized sequences are quite large, and may take a while to
download.
```Shell
wget http://roboimagedata.imm.dtu.dk/data/tar600x800/SET007_12.tar.gz
tar xzf SET007_12.tar.gz

wget http://roboimagedata.imm.dtu.dk/data/tar600x800/SET019_24.tar.gz
tar xzf SET019_24.tar.gz

wget http://roboimagedata.imm.dtu.dk/data/tar600x800/SET043_48.tar.gz
tar xzf SET043_48.tar.gz

wget http://roboimagedata.imm.dtu.dk/data/tar600x800/SET049_54.tar.gz
tar xzf SET049_54.tar.gz
```

Finally, move back into ```datasets``` directory:
```Shell
cd ..
```

#### WebCam dataset

WebCam dataset is available here: http://cvlab.epfl.ch/research/tilde

Download the dataset and extract it into ```webcam``` subdirectory
(if you are extracting manually, move the contents of ```WebcamRelease```
into ```webcam```):
```Shell
mkdir webcam
cd webcam
wget https://documents.epfl.ch/groups/c/cv/cvlab-unit/www/data/keypoints/WebcamRelease.tar.gz
tar xzf /home/rok/Downloads/WebcamRelease.tar.gz  --strip=1
cd ..
```

#### Sanity check

Finally, move out of the datasets directory (back into your working
directory):
```Shell
cd ..
```

Following all the steps up so far, you should end up with the following
directory structure inside your working directory, which is what the
experimental framework will expect to find:
```
code: build_all.bat build_all.sh compile_code.m LICENSE README.md start_matlab.sh startup.m
 - external: lapjv  mexopencv  opencv  opencv_contrib  tight_subplot
 - paper2017: bargraph.tmpl.tex ... jasna_visualizations_webcam.m
 - +vicos: +descriptor +experiment +keypoint_detector +utils

datasets:
 - affine:
    - bark: H1to2p ... H1to6p img1.ppm ... img6.ppm
    - bikes: H1to2p ... H1to6p img1.ppm ... img6.ppm
    - boat: H1to2p ... H1to6p img1.ppm ... img6.ppm
    - graffiti: H1to2p ... H1to6p img1.ppm ... img6.ppm
    - leuven: H1to2p ... H1to6p img1.ppm ... img6.ppm
    - trees: H1to2p ... H1to6p img1.ppm ... img6.ppm
    - ucb: H1to2p ... H1to6p img1.ppm ... img6.ppm
    - wall: H1to2p ... H1to6p img1.ppm ... img6.ppm
 - dtu_robot: Calib_Results_11.mat
    - CleanRecon_2009_11_16: Clean_Reconstruction_01.mat ... Clean_Reconstruction_60.mat
    - SET007: Img001_01.bmp ... Img119_19.bmp
    - SET008: Img001_01.bmp ... Img119_19.bmp
    - SET009: Img001_01.bmp ... Img119_19.bmp
    - SET010: Img001_01.bmp ... Img119_19.bmp
    - SET011: Img001_01.bmp ... Img119_19.bmp
    - SET012: Img001_01.bmp ... Img119_19.bmp
    - SET019: Img001_01.bmp ... Img119_19.bmp
    - SET020: Img001_01.bmp ... Img119_19.bmp
    - SET021: Img001_01.bmp ... Img119_19.bmp
    - SET022: Img001_01.bmp ... Img119_19.bmp
    - SET023: Img001_01.bmp ... Img119_19.bmp
    - SET024: Img001_01.bmp ... Img119_19.bmp
    - SET043: Img001_01.bmp ... Img119_19.bmp
    - SET044: Img001_01.bmp ... Img119_19.bmp
    - SET045: Img001_01.bmp ... Img119_19.bmp
    - SET046: Img001_01.bmp ... Img119_19.bmp
    - SET047: Img001_01.bmp ... Img119_19.bmp
    - SET048: Img001_01.bmp ... Img119_19.bmp
    - SET049: Img001_01.bmp ... Img119_19.bmp
    - SET050: Img001_01.bmp ... Img119_19.bmp
    - SET051: Img001_01.bmp ... Img119_19.bmp
    - SET052: Img001_01.bmp ... Img119_19.bmp
    - SET053: Img001_01.bmp ... Img119_19.bmp
    - SET054: Img001_01.bmp ... Img119_19.bmp
 - webcam: README.txt
    - Chamonix: test train
    - Courbevoie: test train
    - Frankfurt: test train
    - Mexico: test train
    - Panorama: test train
    - StLouis: test train
```

### Linux

To simplify the build process, use the provided ```build_all.sh``` script.

First, export the path to your matlab installation:
```Shell
export MATLABDIR=/usr/local/MATLAB/R2016b
```

Then, run the build script from your working directory:
```Shell
./code/build_all.sh
```

The shell script will attempt to:
- build OpenCV and install it inside the pre-determined sub-directory
  inside the code directory
- build mexopencv (using make)
- run Matlab-side build script ```compile_code.m```, which builds
  additional MEX files

If no errors occurred, the script will print a message about successfully
finishing the build process.

On linux, the OpenCV shared libraries (required by mexopencv) need to be
in your LD_LIBRARY_PATH before Matlab is started. For convenience, a
startup script is provided which takes care of that for your. Therefore,
to start Matlab, run the following script from your working directory:
```Shell
./code/start_matlab.sh
```
It will set up LD_LIBRARY_PATH and run the ```startup.m``` Matlab script
to properly set up paths to external dependencies.


### Windows

Similarly to linux, a build batch script is available. Open the Windows
Prompt (cmd), and move inside the working directory.

Make sure that Matlab and CMake are in the PATH.

Then, set the Visual Studio version and architecture (required for CMake),
and run the build script from the working directory:
```Shell
set "DEFAULT_CMAKE_GENERATOR=Visual Studio 14"
set "DEFAULT_CMAKE_ARCH=x64"

code\build_all.bat
```

The script will attempt to:
- build OpenCV and install it inside the pre-determined sub-directory
  inside the code directory
- run Matlab and build mexopencv
- run Matlab-side build script ```compile_code.m```, which builds
  additional MEX files

If no errors occurred, the script will print a message about successfully
finishing the build process.

On Windows (in contrast to linux; see above), Matlab can be started
normally - but make sure that the ```startup.m``` is executed before
using the functions and objects from this project.


## Basic use

TBA

## Reproduction of experimental results

TBA
