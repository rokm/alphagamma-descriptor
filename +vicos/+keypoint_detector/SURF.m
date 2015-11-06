classdef SURF < vicos.keypoint_detector.OpenCvKeypointDetector
    % SURF - OpenCV SURF keypoint detector
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
    end
    
    methods
        function self = SURF (varargin)
            self.implementation = cv.FeatureDetector('SURF');
        end
    end
end