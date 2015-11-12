classdef SURF < vicos.descriptor.OpenCvDescriptor
    % SURF - OpenCV SURF descriptor extractor
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
    end
    
    methods
        function self = SURF (varargin)
            % self = SURF (varargin)
            %
            % Creates SURF descriptor extractor.
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
            parser.addParameter('HessianThreshold', [], @isnumeric);
            parser.addParameter('NOctaves', [], @isnumeric);
            parser.addParameter('NOctaveLayers', [], @isnumeric);
            parser.addParameter('Extended', [], @islogical);
            parser.addParameter('Upright', [], @islogical);  
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
            self.implementation = cv.DescriptorExtractor('SURF', params{:});
        end
    end
end