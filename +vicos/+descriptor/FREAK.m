classdef FREAK < vicos.descriptor.OpenCvDescriptor
    % FREAK - OpenCV FREAK descriptor extractor
    %
    % (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
    end
    
    methods
        function self = FREAK (varargin)
            % self = FREAK (varargin)
            %
            % Creates FREAK descriptor extractor.
            %
            % Input: optional key/value pairs that correspond directly to
            % the implementation's parameters:
            %  - OrientationNormalized
            %  - ScaleNormalized
            %  - PatternScale
            %  - NOctaves
            %  - SelectedPairs
            % Output:
            %  - @FREAK instance
            
            % Input parser
            parser = inputParser();
            parser.KeepUnmatched = true;            
            parser.addParameter('OrientationNormalized', [], @islogical);
            parser.addParameter('ScaleNormalized', [], @islogical);
            parser.addParameter('PatternScale', [], @isnumeric);
            parser.addParameter('NOctaves', [], @isnumeric);
            parser.addParameter('SelectedPairs', [], @isnumeric);
            parser.parse(varargin{:});
            
            self = self@vicos.descriptor.OpenCvDescriptor(parser.Unmatched);

            %% Create implementation
            params = self.gather_parameters(parser);
            self.implementation = cv.DescriptorExtractor('FREAK', params{:});
        end
    end
    
    methods (Access = protected)
        function identifier = get_identifier (self)
            identifier = 'FREAK';
        end
    end
end