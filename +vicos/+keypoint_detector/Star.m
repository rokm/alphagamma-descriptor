classdef Star < vicos.keypoint_detector.OpenCvKeypointDetector
    % Star - OpenCV Star/CenSurE keypoint detector
    %
    % (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
    end
    
    methods
        function self = Star (varargin)
            % self = Star (varargin)
            %
            % Creates Star keypoint detector.
            %
            % Input: optional key/value pairs that correspond directly to
            % the implementation's parameters:
            %  - MaxSize
            %  - ResponseThreshold
            %  - LineThresholdProjected
            %  - LineThresholdBinarized
            %
            % Output:
            %  - @Star instance
            
            % Input parser
            parser = inputParser();
            parser.KeepUnmatched = true;
            parser.addParameter('MaxSize', [], @isnumeric);
            parser.addParameter('ResponseThreshold', [], @isnumeric);
            parser.addParameter('LineThresholdProjected', [], @isnumeric);
            parser.addParameter('LineThresholdBinarized', [], @isnumeric);
            parser.addParameter('SuppressNonmaxSize', [], @isnumeric);
            parser.parse(varargin{:});
            
            self = self@vicos.keypoint_detector.OpenCvKeypointDetector(parser.Unmatched);

            %% Create implementation
            params = self.gather_parameters(parser);
            self.implementation = cv.FeatureDetector('StarDetector', params{:});
        end
    end
    
    methods (Access = protected)
        function identifier = get_identifier (self)
            identifier = 'Star';
        end
    end
end