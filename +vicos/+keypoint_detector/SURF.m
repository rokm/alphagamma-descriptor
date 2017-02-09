classdef SURF < vicos.keypoint_detector.OpenCvKeypointDetector
    % SURF - OpenCV SURF keypoint detector
    %
    % (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
    end
    
    methods
        function self = SURF (varargin)
            % self = SURF (varargin)
            %
            % Creates SURF keypoint detector.
            %
            % Input: optional key/value pairs that correspond directly to
            % the implementation's parameters:
            %  - HessianThreshold
            %  - NOctaves
            %  - NOctaveLayers
            %  - Extended
            %  - Upright
            %
            % Output:
            %  - @SURF instance
            
            % Input parser
            parser = inputParser();
            parser.KeepUnmatched = true;
            parser.addParameter('HessianThreshold', [], @isnumeric);
            parser.addParameter('NOctaves', [], @isnumeric);
            parser.addParameter('NOctaveLayers', [], @isnumeric);
            parser.addParameter('Extended', [], @islogical);
            parser.addParameter('Upright', [], @islogical);  
            parser.parse(varargin{:});
            
            self = self@vicos.keypoint_detector.OpenCvKeypointDetector(parser.Unmatched);

            %% Create implementation
            params = self.gather_parameters(parser);
            self.implementation = cv.FeatureDetector('SURF', params{:});
        end
    end
    
    methods (Access = protected)
        function identifier = get_identifier (self)
            identifier = 'SURF';
        end
    end
end