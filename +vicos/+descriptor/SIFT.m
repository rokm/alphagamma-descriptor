classdef SIFT < vicos.descriptor.OpenCvDescriptor
    % SIFT - OpenCV SIFT descriptor extractor
    %
    % (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
    end
    
    methods
        function self = SIFT (varargin)
            % self = SIFT (varargin)
            %
            % Creates SIFT descriptor extractor.
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
            parser.KeepUnmatched = true;            
            parser.addParameter('NFeatures', [], @isnumeric);
            parser.addParameter('NOctaveLayers', [], @isnumeric);
            parser.addParameter('ConstrastThreshold', [], @isnumeric);
            parser.addParameter('EdgeThreshold', [], @isnumeric);
            parser.addParameter('Sigma', [], @isnumeric);  
            parser.parse(varargin{:});

            self = self@vicos.descriptor.OpenCvDescriptor(parser.Unmatched);
            
            %% Create implementation           
            params = self.gather_parameters(parser);
            self.implementation = cv.DescriptorExtractor('SIFT', params{:});
        end
    end
    
    methods (Access = protected)
        function identifier = get_identifier (self)
            identifier = 'SIFT';
        end
    end
end