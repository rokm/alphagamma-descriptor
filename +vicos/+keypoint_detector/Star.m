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
            
            parser.addParameter('MaxSize', [], @isnumeric);
            parser.addParameter('ResponseThreshold', [], @isnumeric);
            parser.addParameter('LineThresholdProjected', [], @isnumeric);
            parser.addParameter('LineThresholdBinarized', [], @isnumeric);
            parser.addParameter('SuppressNonmaxSize', [], @isnumeric);
            
            parser.parse(varargin{:});
            
            %% Gather parameters   
            fields = fieldnames(parser.Results);
            params = {};
            for f = 1:numel(fields),
                field = fields{f};
                if ~isempty(parser.Results.(field)),
                    params = [ params, field, parser.Results.(field) ];
                end
            end
            
            %% Create implementation
            self.implementation = cv.FeatureDetector('StarDetector', params{:});
        end
    end
end