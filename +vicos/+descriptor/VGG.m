classdef VGG < vicos.descriptor.OpenCvDescriptor
    % VGG - OpenCV VGG descriptor extractor
    %
    % (C) 2018, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
        type
    end
    
    methods
        function self = VGG (varargin)
            % self = VGG (varargin)
            %
            % Creates VGG descriptor extractor.
            %
            % Input: optional key/value pairs that correspond directly to
            % the implementation's parameters:
            %  - Desc: descriptor type string: '120' (default), '80', '64', '48'
            %  - Sigma: (default: 1.4)
            %  - ImgNormalize: (default: true)
            %  - UseScaleOrientation: (default: true)
            %  - ScaleFactor: (default: 6.25)
            %  - DescNormalize: (default: false)
            %
            % Output:
            %  - @VGG instance
            
            % Input parser
            parser = inputParser();
            parser.KeepUnmatched = true;
            parser.addParameter('Desc', '120', @ischar);
            parser.addParameter('Sigma', [], @isnumeric);
            parser.addParameter('ImgNormalize', [], @islogical);
            parser.addParameter('UseScaleOrientation', [], @islogical);
            parser.addParameter('ScaleFactor', [], @isnumeric);
            parser.addParameter('DescNormalize', [], @islogical);
            parser.parse(varargin{:});

            self = self@vicos.descriptor.OpenCvDescriptor(parser.Unmatched);
            
            %% Create implementation           
            params = self.gather_parameters(parser);
            self.implementation = cv.DescriptorExtractor('VGG', params{:});
            
            % Store type string
            self.type = parser.Results.Desc;
        end
    end
    
    methods (Access = protected)
        function identifier = get_identifier (self)
            identifier = sprintf('VGG%s', self.type);
        end
    end
end
