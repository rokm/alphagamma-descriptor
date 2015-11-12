classdef LATCH < vicos.descriptor.OpenCvDescriptor
    % LATCH - OpenCV BRIEF descriptor extractor
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
    end
    
    methods
        function self = LATCH (varargin)
            % self = LATCH (varargin)
            %
            % Creates LATCH descriptor extractor.
            %
            % Input: optional key/value pairs that correspond directly to
            % the implementation's parameters:
            %  - Bytes
            %  - RotationInvariance
            %  - HalfSize            
            %
            % Output:
            %  - @LATCH instance
            
            % Input parser
            parser = inputParser();
            parser.addParameter('Bytes', [], @isnumeric);
            parser.addParameter('RotationInvariance', [], @islogical);
            parser.addParameter('HalfSize', [], @isnumeric);
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
            self.implementation = cv.DescriptorExtractor('LATCH', params{:});
        end
    end
end