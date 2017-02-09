classdef FAST < vicos.keypoint_detector.OpenCvKeypointDetector
    % FAST - OpenCV FAST keypoint detector
    %
    % (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
    end
    
    methods
        function self = FAST (varargin)
            % self = FAST (varargin)
            %
            % Creates FAST keypoint detector.
            %
            % Input: optional key/value pairs that correspond directly to
            % the implementation's parameters:
            %  - Threshold
            %  - NonmaxSuppression
            %  - Type: TYPE_5_8, TYPE_7_12, TYPE_9_16
            %
            % Output:
            %  - @FAST instance
            
            % Input parser
            parser = inputParser();
            parser.KeepUnmatched = true;
            parser.addParameter('Threshold', [], @isnumeric);
            parser.addParameter('NonmaxSuppression', [], @islogical);
            parser.addParameter('Type', '', @(x) ismember(x, { 'TYPE_5_8', 'TYPE_7_12', 'TYPE_9_16' }));
            parser.parse(varargin{:});
            
            self = self@vicos.keypoint_detector.OpenCvKeypointDetector(parser.Unmatched);
            
            %% Create implementation
            params = self.gather_parameters(parser);
            self.implementation = cv.FeatureDetector('FastFeatureDetector', params{:});
        end
    end
    
    methods (Access = protected)
        function identifier = get_identifier (self)
            identifier = 'FAST';
        end
    end
end