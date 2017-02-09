classdef BRISK < vicos.descriptor.OpenCvDescriptor
    % BRISK - OpenCV BRISK descriptor extractor
    %
    % (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
        
        % The following should make use of the whole patch
        patch_scale_factor = 0.3
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
        
        function desc = compute_from_patch (self, I)
            % Keypoint position: center of the patch
            [ h, w, ~ ] = size(I);
            keypoint.pt = ([ w, h ] - 1) / 2;
            
            % Keypoint size: determined by patch_scale_factor parameter
            keypoint.size = size(I, 1) * self.patch_scale_factor;
            
            % Clear angle and class ID
            keypoint.angle = 0;
            keypoint.class_id = -1;
            
            % Compute descriptor for the keypoint
            desc = self.compute(I, keypoint);
        end
    end
    
    methods (Access = protected)
        function identifier = get_identifier (self)
            identifier = 'BRISK';
        end
    end
end