classdef BRISK < vicos.keypoint_detector.OpenCvKeypointDetector
    % BRISK - OpenCV BRISK keypoint detector
    %
    % (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
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
            %
            % Output:
            %  - @BRISK instance
            
            % Input parser
            parser = inputParser();
            
            parser.addParameter('Threshold', [], @isnumeric);
            parser.addParameter('Octaves', [], @isnumeric);
            parser.addParameter('PatternScale', [], @isnumeric);
            
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
            self.implementation = cv.FeatureDetector('BRISK', params{:});
        end
    end
end