classdef SIFT < vicos.keypoint_detector.OpenCvKeypointDetector
    % SIFT - SIFT keypoint detector
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
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
            %
            % Output:
            %  - @SIFT instance
            
            % Input parser
            parser = inputParser();
            parser.addParameter('NFeatures', [], @isnumeric);
            parser.addParameter('NOctaveLayers', [], @isnumeric);
            parser.addParameter('ConstrastThreshold', [], @isnumeric);
            parser.addParameter('EdgeThreshold', [], @isnumeric);
            parser.addParameter('Sigma', [], @isnumeric);  
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
            self.implementation = cv.FeatureDetector('SIFT', params{:});
        end
    end
end