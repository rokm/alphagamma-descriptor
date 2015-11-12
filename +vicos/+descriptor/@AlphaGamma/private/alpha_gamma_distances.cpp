// distances = ALPHA_GAMMA_DISTANCES (desc1, desc2, num_circles, num_rays)
//
// Computes matrix of pair-wise distances between two sets of AlphaGamma
// descriptors.
//
// Input:
//  - desc1:
//  - desc2:
//  - num_circles:
//  - num_rays:
//
// Output:
//  - distances: N2xN1 double-precision matrix of descriptor distances
//
// (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>

#include <opencv2/core.hpp>
#include <mex.h>

#include <iostream> // For debugging


inline double alpha_gamma_distance (const unsigned char *desc1, const unsigned char *desc2, int numCircles, int numRays, bool extended)
{
    const double A = 5.0;
    const double B = 0.5;
    const double G = 1.0;

    const int lenA = numCircles;
    const int lenB = numRays;
    const int lenG = (numRays-1)*numCircles;

    int distAlpha = 0;
    int distBeta = 0;
    int distGamma = 0;

    // Repeat either once or twice
    for (int r = 0; r < extended; r++) {
        // Alpha effects
        for (int i = 0; i < lenA; i++) {
            distAlpha += (desc1[i] != desc2[i]);
        }
        desc1 += lenA;
        desc2 += lenA;

        // Beta effects
        for (int i = 0; i < lenB; i++) {
            distBeta += (desc1[i] != desc2[i]);
        }
        desc1 += lenB;
        desc2 += lenB;

        // Gamma effects
        for (int i = 0; i < lenG; i++) {
            distGamma += (desc1[i] != desc2[i]);
        }
        desc1 += lenG;
        desc2 += lenG;
    }

    std::cout << "DIST: " << distAlpha << " " << distBeta << " " << distGamma << std::endl;

    return A*distAlpha + B*distBeta + G*distGamma;
}



// *********************************************************************
// *                          MEX entry point                          *
// *********************************************************************
void mexFunction (int nlhs, mxArray **plhs, int nrhs, const mxArray **prhs)
{
    if (nrhs != 5) {
        mexErrMsgTxt("Five input arguments required (desc1, desc2, num_circles, num_rays, extended)!");
    }

    if (nlhs != 1) {
        mexErrMsgTxt("One output argument required!");
    }

    // Validate input
    if (!mxIsNumeric(prhs[2]) || mxGetNumberOfElements(prhs[2]) != 1) {
        mexErrMsgTxt("num_circles must be a numeric scalar!");
    }

    if (!mxIsNumeric(prhs[3]) || mxGetNumberOfElements(prhs[3]) != 1) {
        mexErrMsgTxt("num_rays must be a numeric scalar!");
    }

    const int numCircles = mxGetScalar(prhs[2]);
    const int numRays = mxGetScalar(prhs[3]);
    const int descriptorSize = numCircles + numCircles*numRays;

    std::cout << "NUM C: " << numCircles << " NUM R: " << numRays << " DESC: " << descriptorSize << " M1: " <<mxGetM(prhs[0]) << std::endl;

    if (mxGetClassID(prhs[0]) != mxUINT8_CLASS || (mxGetM(prhs[0]) != descriptorSize && mxGetM(prhs[0]) != 2*descriptorSize)) {
        mexErrMsgTxt("desc1 matrix must be a DxN1 uint8 matrix!");
    }

    if (mxGetClassID(prhs[1]) != mxUINT8_CLASS || (mxGetM(prhs[1]) != descriptorSize && mxGetM(prhs[1]) != 2*descriptorSize)) {
        mexErrMsgTxt("desc2 matrix must be a DxN2 uint8 matrix!");
    }

    if (mxGetM(prhs[0]) != mxGetM(prhs[1])) {
        mexErrMsgTxt("descriptors must be of same size!");
    }

    const bool extendedDescriptor = (mxGetM(prhs[0]) == 2*descriptorSize);

    // Cast the input matrices to CV_8U type
    const cv::Mat desc1 = cv::Mat(mxGetN(prhs[0]), mxGetM(prhs[0]), CV_8U, mxGetData(prhs[0]));
    const cv::Mat desc2 = cv::Mat(mxGetN(prhs[1]), mxGetM(prhs[1]), CV_8U, mxGetData(prhs[1]));

    // *** Compute distance matrix ***
    plhs[0] = mxCreateNumericMatrix(desc2.rows, desc1.rows, mxDOUBLE_CLASS, mxREAL);
    cv::Mat distances = cv::Mat(mxGetN(plhs[0]), mxGetM(plhs[0]), CV_64F, mxGetData(plhs[0])); // Note switched dimensions

    for (int i = 0; i < desc1.rows; i++) {
        double *distPtr = distances.ptr<double>(i);
        const unsigned char *desc1p = desc1.ptr<unsigned char>(i);
        for (int j = 0; j < desc2.rows; j++) {
            const unsigned char *desc2p = desc2.ptr<unsigned char>(j);

            distPtr[j] = alpha_gamma_distance(desc1p, desc2p, numCircles, numRays, extendedDescriptor);
        }
    }
}
