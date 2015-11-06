// distances = COMPUTE_KEYPOINT_DISTANCES (keypoints1, keypoints2)
//
// Computes matrix of pair-wise Euclidean distances between two sets of
// keypoints.
//
// Input:
//  - keypoints1: 2xN1 double-precision matrix of center coordinates for
//    the first set of keypoints
//  - keypoints2: 2xN2 double-precision matrix of center coordinates for
//    the second set of keypoints
//
// Output:
//  - distances: N2xN1 double-precision matrix of Euclidean distances
//
// (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>

#include <opencv2/core.hpp>
#include <mex.h>

#include <iostream> // For debugging


template<typename T> inline T square (const T &x) {
    return x * x;
}

// *********************************************************************
// *                          MEX entry point                          *
// *********************************************************************
void mexFunction (int nlhs, mxArray **plhs, int nrhs, const mxArray **prhs)
{
    if (nrhs != 2 && nrhs != 3) {
        mexErrMsgTxt("Two or three input arguments required (keypoints1, keypoints2, distance_threshold)!");
    }

    if (nlhs != 1 && nlhs != 2) {
        mexErrMsgTxt("One or two output arguments required!");
    }

    // Validate input
    if (mxGetClassID(prhs[0]) != mxDOUBLE_CLASS || mxGetM(prhs[0]) != 2) {
        mexErrMsgTxt("keypoints1 matrix must be a 2xN1 double matrix!");
    }

    if (mxGetClassID(prhs[1]) != mxDOUBLE_CLASS || mxGetM(prhs[1]) != 2) {
        mexErrMsgTxt("keypoints2 matrix must be a 2xN2 double matrix!");
    }
    
    double distanceThreshold = 2.5;
    if (nrhs > 2) {
        distanceThreshold = mxGetScalar(prhs[2]);
    }

    // We manually cast the input matrices to CV_64FC2 type, in order to
    // have faster access to the data
    const cv::Mat keypoints1 = cv::Mat(mxGetN(prhs[0]), 1, CV_64FC2, mxGetData(prhs[0]));
    const cv::Mat keypoints2 = cv::Mat(mxGetN(prhs[1]), 1, CV_64FC2, mxGetData(prhs[1]));

    // *** Compute distance matrix ***
    plhs[0] = mxCreateNumericMatrix(keypoints2.rows, keypoints1.rows, mxDOUBLE_CLASS, mxREAL);
    cv::Mat distances = cv::Mat(mxGetN(plhs[0]), mxGetM(plhs[0]), CV_64F, mxGetData(plhs[0])); // Note switched dimensions

    for (int i = 0; i < keypoints1.rows; i++) {
        double *distPtr = distances.ptr<double>(i);
        const cv::Vec2d &pt1 = keypoints1.at<cv::Vec2d>(i);
        for (int j = 0; j < keypoints2.rows; j++) {
            const cv::Vec2d &pt2 = keypoints2.at<cv::Vec2d>(j);
            // Use manual implementation of L2 norm
            distPtr[j] = cv::sqrt( square(pt1[0] - pt2[0]) + square(pt1[1] - pt2[1]) );
        }
    }

    if (nlhs < 2) {
        return;
    }

    // *** Compute the (greedy) matching ***
    int matchCount = 0;
    plhs[1] = mxCreateNumericMatrix(keypoints2.rows, keypoints1.rows, mxDOUBLE_CLASS, mxREAL);
    cv::Mat matches = cv::Mat(mxGetN(plhs[1]), mxGetM(plhs[1]), CV_64F, mxGetData(plhs[1])); // Note switched dimensions

    cv::Mat maskedDistances;
    distances.copyTo(maskedDistances);
    const double inf = std::numeric_limits<double>::infinity();

    while (true) {
        double minValue = inf;
        cv::Point minLoc;

        cv::minMaxLoc(maskedDistances, &minValue, NULL, &minLoc, NULL, cv::noArray());

        if (minValue > distanceThreshold || minLoc.x == -1 || minLoc.y == -1) {
            break;
        }

        matches.at<double>(minLoc.y, minLoc.x) = ++matchCount;
        maskedDistances.row(minLoc.y) = inf;
        maskedDistances.col(minLoc.x) = inf;
    }
}
