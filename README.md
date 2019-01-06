# AlphaGamma keypoint descriptor #

**Prototype & evaluation framework**

(C) 2015-2017, Rok Mandeljc


## Summary

This project contains the prototype implementation of the AlphaGamma
keypoint descriptor, presented in:

1. R. Mandeljc and J. Maver, AGs: Local descriptors dervied from the
   dependent effects model, Journal of Visual Communication and Image
   Representation, Volume 58, p. 503-514, January 2019.
   DOI: [10.1016/j.jvcir.2018.12.008](https://doi.org/10.1016/j.jvcir.2018.12.008)


The code is provided as supplement to the journal submission [1], and
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
```Batchfile
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

This package provides reference implementation for AlphaGamma descriptor
and RADIAL keypoint detector, as well as wrappers for several OpenCV-provided
detectoes and the descriptors.

Keypoint detector and descriptor extractor classes are located inside
```vicos.keypoint_detector``` and ```vicos.descriptor``` namespace, respectively.

All detectors inherit the base class ```vicos.keypoint_detector.Detector```,
with method ```vicos.keypoint_detector.Detector.detect()``` that is used
for detecting keypoints in the image.

Similarly, descriptor extractors inherit the base class ```vicos.descriptor.Descriptor```,
with two main methods: ```vicos.descriptor.Descriptor.compute()``` is used
to compute descriptors from given keypoints and image, while
```vicos.descriptor.Descriptor.compute_pairwise_distances()``` is used
to compute the distance matrix between two sets of exracted descriptors.

The following example illustrates the use of RADIAL keypoints with
AG and AGS descriptors. The static methods
```vicos.descriptor.AlphaGamma.create_ag_float()```
and
```vicos.descriptor.AlphaGamma.create_ag_short()```
provide the default parametrization of AG and AGS descriptor from the
paper [1].

```Matlab
% Load images (assuming datasets were installed and that we are inside
% the working directory)
I1 = imread('datasets/affine/graffiti/img1.ppm');
I2 = imread('datasets/affine/graffiti/img2.ppm');


%% Keypoint detection
% Create RADIAL keypoint detector
detector = vicos.keypoint_detector.FeatureRadial();

% Detect keypoints
kpts1 = detector.detect(I1);
kpts2 = detector.detect(I2);


%% AG descriptor
% Create floating-point AlphaGamma;
ag_float = vicos.descriptor.AlphaGamma.create_ag_float('base_keypoint_size', 8.25);

% Compute descriptors
[ desc1, kpts1 ] = ag_float.compute(I1, kpts1);
[ desc2, kpts2 ] = ag_float.compute(I2, kpts2);

% Compute distance matrix
M = ag_float.compute_pairwise_distances(desc1, desc2);


%% AGS descriptor
% Create binarized AlphaGamma
ag_short = vicos.descriptor.AlphaGamma.create_ag_short('base_keypoint_size', 8.0);

% Compute descriptors
[ desc1, kpts1 ] = ag_short.compute(I1, kpts1);
[ desc2, kpts2 ] = ag_short.compute(I2, kpts2);

% Compute distance matrix
M = ag_short.compute_pairwise_distances(desc1, desc2);
```

An example with SIFT keypoints:
```Matlab
% Load images (assuming datasets were installed and that we are inside
% the working directory)
I1 = imread('datasets/affine/graffiti/img1.ppm');
I2 = imread('datasets/affine/graffiti/img2.ppm');


%% Keypoint detection
% Create SIFT keypoint detector
detector = vicos.keypoint_detector.SIFT();

% Detect keypoints
kpts1 = detector.detect(I1);
kpts2 = detector.detect(I2);


%% SIFT descriptor
sift = vicos.descriptor.SIFT();

% Compute descriptors
[ desc1, kpts1 ] = sift.compute(I1, kpts1);
[ desc2, kpts2 ] = sift.compute(I2, kpts2);

% Compute distance matrix
M = sift.compute_pairwise_distances(desc1, desc2);


%% AG descriptor
% Create floating-point AlphaGamma; note that in general, different
% keypoint types require different base_keypoint_size parameter.
ag_float = vicos.descriptor.AlphaGamma.create_ag_float('base_keypoint_size', 3.25);

% Compute descriptors
[ desc1, kpts1 ] = ag_float.compute(I1, kpts1);
[ desc2, kpts2 ] = ag_float.compute(I2, kpts2);

% Compute distance matrix
M = ag_float.compute_pairwise_distances(desc1, desc2);
```


## Reproduction of experimental results

The experimental results from the paper [1] were all obtained using
scripts that are located in the ```paper2017``` subfolder inside the
code folder.

By default, all experiment functions cache their intermediate
and final results; when run subsequently, they will attempt to load
cached results before running the experiment. Therefore, the longer
experiments can be left to run unattended, and be later re-run with
additional options to enable visualization of results.

*NOTE:* it is assumed that the code snippets below are executed from the
working directory as to avoid cluttering the code directory with cache
directories and result files.


### Synthetic deformations

To reproduce results with synthetic image rotation (Fig. 6a), use
function ```jasna_experiment_rotation()```:

```Matlab
% Run all experiments (or load cached results).
jasna_experiment_rotation();

% Run all experiments (or load cached results), display Matlab figure,
% and export results to rotation.txt file
jasna_experiment_rotation('display_results', true, 'result_file', 'rotation-results.txt');
```

Similarly, results for scale (Fig. 6b) and shear (Fig. 6c) can be
reproduced using:

```Matlab
jasna_experiment_scale('display_results', true, 'result_file', 'scale-results.txt');

jasna_experiment_shear('display_results', true, 'result_file', 'shear-results.txt');
```

### Experiments on image sequences

The experiments on image sequences (Figs. 5, 7, 8, 9) can be reproduced
by running the following functions:

```Matlab
% All experiments on sequences from Oxford dataset (by default, the
% following sequences are used: bikes, trees, leuven, boat, graffiti,
% and wall)
jasna_experiment_affine({ 'sift', 'surf', 'kaze', 'brisk', 'orb', 'radial' });

% All experiments on sequences from Frankfurt dataset (by default, the
% following sequence is used: Frankfurt)
jasna_experiment_webcam({ 'sift', 'surf', 'kaze', 'brisk', 'orb', 'radial' });

% All experiments on sequences from DTU dataset (by default, the following
% sequences are used: SET007, SET022, SET023, and SET049)
jasna_experiment_dtu({ 'sift', 'surf', 'kaze', 'brisk', 'orb', 'radial' });
```

The mandatory argument is cell array containing the pre-defined names of
experiments. For each experiment id, the keypoints are tested with the
native descriptor and both AG and AGS (i.e., SIFT, AG, and AGS on SIFT
keypoints for 'sift' experiment id).

The experiments will take a while to run. A possible way to parallelize
them is to run multiple Matlab instances, and execute the experiment
functions with different subsets of above experiment IDs.

The intermediate and final results are cached in corresponding cache
directories. To display the final results as shown in paper, use the
```jasna_display_results()``` function. Note that this function assumes
that experiments have been run for all six experiment IDs that are
shown above.

```Matlab
% Oxford sequences; show Matlab figures and export LaTeX code for graphs
jasna_display_results('_cache_affine-gray', { 'bikes', 'trees', 'leuven', 'boat', 'graffiti', 'wall' }, 'display_figure', true, 'output_dir', 'graphs-affine');

% Webcam sequence; show only Matlab figures (same as if 'display_figure' option was also omitted)
jasna_display_results('_cache_webcam-gray', { 'Frankfurt' }, 'display_figure', true);

% DTU sequences; do not display Matlab figures, but export the LaTeX code for graphs.
jasna_display_results('_cache_dtu-gray', { 'SET007', 'SET022', 'SET023', 'SET049' }, 'output_dir', 'graphs-dtu', 'display_figure', false);
```

The first argument is the name of cache directory that was created by
the experiment script. The second argument is cell array with names of
sequences (used as prefix for result files inside cache directory).

The 'display_figure' is an optional argument and controls whether
Matlab figures with graphs should be created (enabled by default).

The 'output_dir' is an optional argument and controls, whether LaTeX
code for graphs is exported (to the specified directory), or not
(disabled by default). The specified output directory will contain
several .tex files, one for each graph.


## Correct match visualizations

Visualizations of correct matches in Fig. 10 were obtained using the
following function:

```Matlab
jasna_visualizations_dtu();
```

The above function will run the relevant experiments. By default, it
uses different cache directory than experiment scripts from the
previous section. Inside this cache directory, called
```_visualization_dtu-gray```, it will create several folders containing
data and LaTeX code for visualizations. For example, folder
_visualization_dtu-gray/SET010_Img025_08_Img119_08_SIFT_SIFT will
contain LaTeX code and data for visualization of correct matches of
SIFT descriptor on SIFT keypoints, when used on images 25 and 119 from
DTU SET010.

A similar function can be used to generate some visualizations for
sequences from the WebCam dataset:
```Matlab
jasna_visualizations_webcam();
```

The resulting images were excluded from the paper due to page limit.


## LIFT keypoint detector/descriptor support

This repository incorporates support for the LIFT keypoint detector and
descriptor from: https://github.com/cvlab-epfl/LIFT

As with other components, the code from above repository is incorporated
as git submodule and wrapper classes (```vicos.keypoint_detector.LIFT``` and
```vicos.descriptor.LIFT```). Due to CUDA and python dependencies
(Theano, lasagne, etc.) and limited testing, the support is limited
to linux-based operating systems for now.

The instructions below are written for Fedora 25/26, where integration
was developed and tested.


### Dependencies

LIFT code requires a CUDA-compatible GPU.

For CUDA and CuDNN, Fedora packages are available in Negativo17 repository:
https://negativo17.org/nvidia-driver

After setting it up, install cuda and cudnn (version 5):
```Shell
sudo dnf install cuda-devel cuda-cudnn5.1-devel
```

On Fedora 25/26, the dependencies can be install directly from official
repositories:

```Shell
sudo dnf install python2-opencv python2-h5py python2-flufl-lock python2-parse python2-scipy python2-theano
```

We also need python2-lasagne, but Fedora (at the time of writing)
provides incompatible (outdated) 0.1 version, which does not work
with Theano/LIFT. Hence, you need to install the development version
on your own, or grab it from the following Copr repository: (TBA)

### Building C++ part

The LIFT code also includes some C++ code that needs to be compiled;
this is handled by the master build script (from beginning of this README):

```Shell
./code/build_all.sh
```

### Setting up Theano

Fedora 26 comes with gcc compiler version that is incompatible with
CUDA 8. Installing cuda packages from Negativo17 repository should also
pull in the compat-gcc-53 packages. However, we need to instruct
Theano to use it when compiling generated code. Create ~/.theanorc
file with the following content:

```
[nvcc]
flags=-D_FORCE_INLINES -ccbin=/usr/bin/g++53

[global]
floatX = float32
device = cuda0
```

The floatX and device settings are necessary to avoid  messages about
using old gpu back-end and floatX=64.


### Using LIFT wrapper

LIFT detector/descriptor can be used in same way as other wrapped
detectors and descriptors, e.g.:

```Matlab
% Load images (assuming datasets were installed and that we are inside
% the working directory)
I1 = imread('datasets/affine/graffiti/img1.ppm');
I2 = imread('datasets/affine/graffiti/img2.ppm');


%% Keypoint detection
% Create LIFT keypoint detector
detector = vicos.keypoint_detector.LIFT();

% Detect keypoints
kpts1 = detector.detect(I1);
kpts2 = detector.detect(I2);


%% LIFT descriptor
lift = vicos.descriptor.LIFT();

% Compute descriptors
[ desc1, kpts1 ] = lift.compute(I1, kpts1);
[ desc2, kpts2 ] = lift.compute(I2, kpts2);

% Compute distance matrix
M = lift.compute_pairwise_distances(desc1, desc2);
```

The first run may take a while as it, behind the scenes, performs
compilation of auto-generated code.

### Using LIFT in experiments code

To activate LIFT experiments, use ```'lift'``` experiment name when calling
```jasna_experiment_affine()```, ```jasna_experiment_webcam()```, and
```jasna_experiment_dtu()```.
