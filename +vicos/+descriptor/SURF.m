classdef SURF < vicos.descriptor.OpenCvDescriptor
    % SURF - OpenCV SURF descriptor extractor
    %
    % (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
        
        % The following scale factor should theoretically make use of the 
        % whole patch
        patch_scale_factor = 1 / (9.0/1.2 * 1/(20+1))
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
            parser.KeepUnmatched = true;            
            parser.addParameter('HessianThreshold', [], @isnumeric);
            parser.addParameter('NOctaves', [], @isnumeric);
            parser.addParameter('NOctaveLayers', [], @isnumeric);
            parser.addParameter('Extended', [], @islogical);
            parser.addParameter('Upright', [], @islogical);  
            parser.parse(varargin{:});
            
            self = self@vicos.descriptor.OpenCvDescriptor(parser.Unmatched);
            
            %% Create implementation
            params = self.gather_parameters(parser);            
            self.implementation = cv.DescriptorExtractor('SURF', params{:});
        end
        
        function desc = compute_from_patch (self, I)            
            % SURF implementation has a PATCH_SIZE constant of 20; when
            % computing descriptor, it takes the keypoint's size parameter,
            % and multiplies it by 1.2/9.0, and divides by (PATCH_SIZE+1)
            % to obtain the sampling window around the keypoint...
            
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
            identifier = 'SURF';
        end
    end
end