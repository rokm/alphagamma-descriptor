classdef SIFT < vicos.descriptor.OpenCvDescriptor
    % SIFT - OpenCV SIFT descriptor extractor
    %
    % (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
        
        patch_scale_factor = 10
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
        
        function desc = compute_from_patch (self, I)
            % Keypoint position: center of the patch
            [ h, w, ~ ] = size(I);
            keypoint.pt = ([ w, h ] - 1) / 2;
            
            % Keypoint size: determined by patch_scale_factor parameter
            keypoint.size = size(I, 1) / self.patch_scale_factor;
            
            keypoint.angle = 0;
            keypoint.class_id = -1;
            
            % Compute descriptor for the keypoint
            desc = self.compute(I, keypoint);
        end
    end
    
    methods (Access = protected)
        function identifier = get_identifier (self)
            identifier = 'SIFT';
        end
    end
end