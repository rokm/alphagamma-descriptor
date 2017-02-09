classdef Harris < vicos.keypoint_detector.OpenCvKeypointDetector
    % Harris - OpenCV Harris keypoint detector
    %
    % (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
    end
    
    methods
        function self = Harris (varargin)
            % self = Harris (varargin)
            %
            % Creates Harris keypoint detector.
            %
            % Input: optional key/value pairs that correspond directly to
            % the implementation's parameters:
            %  - MaxFeatures
            %  - QualityLevel
            %  - MinDistance
            %  - BlockSize
            %  - K
            %
            % Output:
            %  - @Harris instance
            
            % Input parser
            parser = inputParser();
            parser.KeepUnmatched = true;
            parser.addParameter('MaxFeatures', 0, @isnumeric);
            parser.addParameter('QualityLevel', [], @isnumeric);
            parser.addParameter('MinDistance', [], @isnumeric);
            parser.addParameter('BlockSize', [], @isnumeric);
            parser.addParameter('K', [], @isnumeric);
            parser.parse(varargin{:});

            self = self@vicos.keypoint_detector.OpenCvKeypointDetector(parser.Unmatched);

            %% Create implementation
            params = self.gather_parameters(parser);
            self.implementation = cv.FeatureDetector('GFTTDetector', 'HarrisDetector', true, params{:});
        end
    end
    
    methods (Access = protected)
        function identifier = get_identifier (self)
            identifier = 'Harris';
        end
    end
end