classdef SIFT < vicos.keypoint_detector.OpenCvKeypointDetector
    % SIFT - SIFT keypoint detector
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
    end
    
    methods
        function self = SIFT (varargin)
            self.implementation = cv.FeatureDetector('SIFT');
        end
    end
end