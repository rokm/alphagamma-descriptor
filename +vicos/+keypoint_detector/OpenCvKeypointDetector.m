classdef OpenCvKeypointDetector < vicos.keypoint_detector.KeypointDetector
    % OPENCVKEYPOINTDETECTOR - base class for OpenCV keypoint detector implementations
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties (Abstract)
        % Provided by child via cv::featureDetector()
        implementation
    end
    
    methods
        function keypoints = detect (self, I)
            % Detect keypoints using the child-provided implementation
            keypoints = self.implementation.detect(I);
        end
    end
end