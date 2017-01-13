classdef LIFT < vicos.keypoint_detector.KeypointDetector
    % LIFT - LIFT keypoint detector
    %
    % This class uses vicos.misc.LiftWrapper class to implement LIFT
    % keypoint detector.
    %
    % K. M. Yi, E. Trulls, V. Lepetit, and P. Fua. "LIFT: Learned Invariant 
    % Feature Transform", European Conference on Computer Vision (ECCV), 2016.
    %
    % (C) 2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        wrapper
    end
    
    methods
        function self = LIFT (varargin)
            % self = LIFT (varargin)
            %
            % Creates LIFT keypoint detector.
            %
            % Input: optional key/value pairs:
            %
            % Output:
            %  - self:
            
            % Input parser
            parser = inputParser();
            parser.parse(varargin{:});
            
            % Create LIFT wrapper
            self.wrapper = vicos.misc.LiftWrapper();
        end
        
        function keypoints = detect (self, I)
            % Use wrapper
            keypoints = self.wrapper.detect_lift_keypoints(I);
        end
    end
end