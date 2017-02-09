classdef BRISK < vicos.keypoint_detector.OpenCvKeypointDetector
    % BRISK - OpenCV BRISK keypoint detector
    %
    % (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
        
        upright
    end
    
    methods
        function self = BRISK (varargin)
            % self = BRISK (varargin)
            %
            % Creates BRISK keypoint detector.
            %
            % Input: optional key/value pairs that correspond directly to
            % the implementation's parameters:
            %  - Threshold
            %  - Octaves
            %  - PatternScale
            %  - UpRight: manually zero the angles returned by the detector
            %
            % Output:
            %  - @BRISK instance
            
            % Input parser
            parser = inputParser();
            parser.KeepUnmatched = true;
            parser.addParameter('Threshold', [], @isnumeric);
            parser.addParameter('Octaves', [], @isnumeric);
            parser.addParameter('PatternScale', [], @isnumeric);
            parser.addParameter('UpRight', false, @islogical);
            parser.parse(varargin{:});

            self = self@vicos.keypoint_detector.OpenCvKeypointDetector(parser.Unmatched);
            self.upright = parser.Results.UpRight;
            
            %% Create implementation
            params = self.gather_parameters(parser, 'UpRight');
            self.implementation = cv.FeatureDetector('BRISK', params{:});
        end
        
        function keypoints = detect (self, I)
            % Detect keypoints using the child-provided implementation
            keypoints = self.implementation.detect(I);
            
            if self.upright
                [ keypoints.angle ] = deal(0);
            end
        end
    end
    
    methods (Access = protected)
        function identifier = get_identifier (self)
            identifier = 'BRISK';
        end
    end
end