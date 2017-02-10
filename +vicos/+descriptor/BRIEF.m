classdef BRIEF < vicos.descriptor.OpenCvDescriptor
    % BRIEF - OpenCV BRIEF descriptor extractor
    %
    % (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
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
            parser.KeepUnmatched = true;            
            parser.addParameter('Bytes', [], @isnumeric);
            parser.addParameter('UseOrientation', [], @islogical);  
            parser.parse(varargin{:});
            
            self = self@vicos.descriptor.OpenCvDescriptor(parser.Unmatched);
                        
            %% Create implementation
            params = self.gather_parameters(parser);
            self.implementation = cv.DescriptorExtractor('BriefDescriptorExtractor', params{:});
        end
    end
    
    methods (Access = protected)
        function identifier = get_identifier (self)
            identifier = 'BRIEF';
        end
    end
end