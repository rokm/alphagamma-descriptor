classdef Descriptor < handle
    % DESCRIPTOR - base class for keypoint detector implementations
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    methods (Abstract)
        % [ descriptors, keypoints ] = COMPUTE (self, I, keypoints)
        %
        % Extracts descriptors from the specified keypoints in the given
        % image.
        %
        % NOTE: the implementation may decide to remove some of the
        % keypoints, or add new keypoints. Therefore, in addition to the
        % computed descriptors, the array of corresponding keypoints is
        % also returned by this method.
        %
        % Input:
        %  - self: @Descriptor instance
        %  - I: image
        %  - keypoints: 1xN array keypoints
        %
        % Output:
        %  - descriptors: MxD matrix of descriptors
        %  - keypoints: 1xM array of keypoints        
        [ descriptors, keypoints ] = compute (self, I, keypoints)
        
        % distances = COMPUTE_PAIRWISE_DISTANCES (self, desc1, desc2)
        %
        % Computes a matrix of pair-wise distances between two sets of
        % keypoint descriptors.
        %
        % Input:
        %  - self: @Descriptor instance
        %  - desc1: N1xD matrix of descriptors for first set of keypoints
        %  - desc2: N2xD matrix of descriptors for second set of keypoints
        %
        % Output:
        %  - distances: N2xN1 matrix of pair-wise distances between
        %    descriptors. Each column corresponds to a descriptor from the
        %    first set, and eeach row corresponds to a descriptor from the
        %    second set
        distances = compute_pairwise_distances (self, desc1, desc2)
    end
end