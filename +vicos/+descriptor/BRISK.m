classdef BRISK < vicos.descriptor.OpenCvDescriptor
    % BRISK - OpenCV BRISK descriptor extractor
    %
    % (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
    end
    
    methods
        function self = BRISK (varargin)
            % self = BRISK (varargin)
            %
            % Creates BRISK descriptor extractor.
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
            parser.KeepUnmatched = true;            
            parser.addParameter('Threshold', [], @isnumeric);
            parser.addParameter('Octaves', [], @isnumeric);
            parser.addParameter('PatternScale', [], @isnumeric);
            parser.parse(varargin{:});

            self = self@vicos.descriptor.OpenCvDescriptor(parser.Unmatched);

            %% Create implementation
            params = self.gather_parameters(parser);
            self.implementation = cv.DescriptorExtractor('BRISK', params{:});
        end
    end
    
    methods (Access = protected)
        function identifier = get_identifier (self)
            identifier = 'BRISK';
        end
    end
end