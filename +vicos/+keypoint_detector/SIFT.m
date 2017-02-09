classdef SIFT < vicos.keypoint_detector.OpenCvKeypointDetector
    % SIFT - SIFT keypoint detector
    %
    % (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
        
        upright
    end
    
    methods
        function self = SIFT (varargin)
            % self = SIFT (varargin)
            %
            % Creates SIFT keypoint detector.
            %
            % Input: optional key/value pairs that correspond directly to
            % the implementation's parameters:
            %  - NFeatures
            %  - NOctaveLayers
            %  - ConstrastThreshold
            %  - EdgeThreshold
            %  - Sigma
            %  - UpRight: manually zero the angles returned by the detector
            %
            % Output:
            %  - @SIFT instance
            
            % Input parser
            parser = inputParser();
            parser.KeepUnmatched = true;
            parser.addParameter('NFeatures', [], @isnumeric);
            parser.addParameter('NOctaveLayers', [], @isnumeric);
            parser.addParameter('ConstrastThreshold', [], @isnumeric);
            parser.addParameter('EdgeThreshold', [], @isnumeric);
            parser.addParameter('Sigma', [], @isnumeric);  
            parser.addParameter('UpRight', false, @islogical);  
            parser.parse(varargin{:});
            
            self = self@vicos.keypoint_detector.OpenCvKeypointDetector(parser.Unmatched);
            self.upright = parser.Results.UpRight;
            
            %% Create implementation            
            params = self.gather_parameters(parser, 'UpRight');
            self.implementation = cv.FeatureDetector('SIFT', params{:});
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
            identifier = 'SIFT';
        end
    end
end