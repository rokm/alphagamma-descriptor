classdef KeypointDetector < handle
    % KEYPOINTDETECTOR - base class for keypoint detector implementations
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    methods (Abstract)
        % keypoints = DETECT (self, I)
        %
        % Detect keypoints in the given image
        %
        % Input:
        %  - self: @KeypointDetector instance
        %  - I: image
        %
        % Output:
        %  - keypoints: array of OpenCV keypoint structures
        %
        keypoints = detect (self, I)
    end
end