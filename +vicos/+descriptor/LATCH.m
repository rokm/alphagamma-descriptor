classdef LATCH < vicos.descriptor.OpenCvDescriptor
    % LATCH - OpenCV LATCH descriptor extractor
    %
    % (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
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
            parser.KeepUnmatched = true;            
            parser.addParameter('Bytes', [], @isnumeric);
            parser.addParameter('RotationInvariance', [], @islogical);
            parser.addParameter('HalfSize', [], @isnumeric);
            parser.parse(varargin{:});

            self = self@vicos.descriptor.OpenCvDescriptor(parser.Unmatched);

            %% Create implementation
            params = self.gather_parameters(parser);
            self.implementation = cv.DescriptorExtractor('LATCH', params{:});
        end
    end
    
    methods (Access = protected)
        function identifier = get_identifier (self)
            identifier = 'LATCH';
        end
    end
end