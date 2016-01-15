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
            %  - @BRISK instance
            
            % Input parser
            parser = inputParser();
            
            parser.addParameter('MaxFeatures', 0, @isnumeric);
            parser.addParameter('QualityLevel', [], @isnumeric);
            parser.addParameter('MinDistance', [], @isnumeric);
            parser.addParameter('BlockSize', [], @isnumeric);
            parser.addParameter('K', [], @isnumeric);
            
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
            self.implementation = cv.FeatureDetector('GFTTDetector', 'HarrisDetector', true, params{:});
        end
    end
end