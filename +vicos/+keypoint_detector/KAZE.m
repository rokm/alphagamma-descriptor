classdef KAZE < vicos.keypoint_detector.OpenCvKeypointDetector
    % KAZE - OpenCV KAZE keypoint detector
    %
    % (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
    end
    
    methods
        function self = KAZE (varargin)
            % self = KAZE (varargin)
            %
            % Creates KAZE keypoint detector.
            %
            % Input: optional key/value pairs that correspond directly to
            % the implementation's parameters:
            %  - Extended
            %  - Upright
            %  - Threshold
            %  - NOctaves
            %  - NOctaveLayers
            %  - Diffusivity
            %
            % Output:
            %  - @KAZE instance
            
            % Input parser
            parser = inputParser();
            parser.addParameter('Extended', [], @islogical);
            parser.addParameter('Upright', [], @islogical);
            parser.addParameter('Threshold', [], @isnumeric);
            parser.addParameter('NOctaves', [], @isnumeric);
            parser.addParameter('NOctaveLayers', [], @isnumeric);
            parser.addParameter('Diffusivity', [], @isnumeric);
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
            self.implementation = cv.FeatureDetector('KAZE', params{:});
        end
    end
end