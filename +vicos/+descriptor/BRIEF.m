classdef BRIEF < vicos.descriptor.OpenCvDescriptor
    % BRIEF - OpenCV BRIEF descriptor extractor
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
    end
    
    methods
        function self = BRIEF (varargin)
            % self = BRIEF (varargin)
            %
            % Creates BRIEF descriptor extractor.
            %
            % Input: optional key/value pairs that correspond directly to
            % the implementation's parameters:
            %  - Bytes
            %  - UseOrientation
            %
            % Output:
            %  - @BRIEF instance
            
            % Input parser
            parser = inputParser();
            parser.addParameter('Bytes', [], @isnumeric);
            parser.addParameter('UseOrientation', [], @islogical);  
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
            self.implementation = cv.DescriptorExtractor('BriefDescriptorExtractor', params{:});
        end
    end
end