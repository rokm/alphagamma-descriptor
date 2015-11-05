% distances = COMPUTE_KEYPOINT_DISTANCES (keypoints1, keypoints2)
%
% Computes matrix of pair-wise Euclidean distances between two sets of
% keypoints.
%
% Input:
%  - keypoints1: 2xN1 double-precision matrix of center coordinates for
%    the first set of keypoints
%  - keypoints2: 2xN2 double-precision matrix of center coordinates for
%    the second set of keypoints
%
% Output:
%  - distances: N2xN1 double-precision matrix of Euclidean distances
%
% (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>

% Make sure we have the MEX
assert( exist('compute_keypoint_distances', 'file') == 3, 'MEX file does not exist; run make.m!');