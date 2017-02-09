classdef KAZE < vicos.descriptor.OpenCvDescriptor
    % KAZE - OpenCV KAZE descriptor extractor
    %
    % (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
        
        % The following should make use of the whole patch
        keypoint_size = 24
    end
    
    methods
        function self = KAZE (varargin)
            % self = KAZE (varargin)
            %
            % Creates KAZE descriptor extractor.
            %
            % Input: optional key/value pairs that correspond directly to
            % the implementation's parameters:
            %  - Extended
            %  - Upright
            %  - Threshold
            %  - NOctaves
            %  - NOctaveLayers
            %  - Diffusivity
            %
            % Output:
            %  - @KAZE instance
            
            % Input parser
            parser = inputParser();
            parser.KeepUnmatched = true;            
            parser.addParameter('Extended', [], @islogical);
            parser.addParameter('Upright', [], @islogical);
            parser.addParameter('Threshold', [], @isnumeric);
            parser.addParameter('NOctaves', [], @isnumeric);
            parser.addParameter('NOctaveLayers', [], @isnumeric);
            parser.addParameter('Diffusivity', [], @isnumeric);
            parser.parse(varargin{:});

            self = self@vicos.descriptor.OpenCvDescriptor(parser.Unmatched);
            
            %% Create implementation
            params = self.gather_parameters(parser);
            self.implementation = cv.DescriptorExtractor('KAZE', params{:});
        end
        
        function desc = compute_from_patch (self, I)            
            % Keypoint position: center of the patch
            [ h, w, ~ ] = size(I);
            keypoint.pt = ([ w, h ] - 1) / 2;
            
            % Keypoint size: determined by patch_scale_factor parameter
            keypoint.size = self.keypoint_size;
            
            keypoint.octave = 1; % KAZE descriptor needs octave to ne specified!
            
            keypoint.angle = 0;            
            keypoint.class_id = -1;
            
            % Compute descriptor for the keypoint
            desc = self.compute(I, keypoint);
        end
    end
    
    methods (Access = protected)
        function identifier = get_identifier (self)
            identifier = 'KAZE';
        end
    end
end