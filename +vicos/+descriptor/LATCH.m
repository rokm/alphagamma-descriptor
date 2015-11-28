classdef LATCH < vicos.descriptor.OpenCvDescriptor
    % LATCH - OpenCV BRIEF descriptor extractor
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
        
        patch_size = 56
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
            parser.addParameter('Bytes', [], @isnumeric);
            parser.addParameter('RotationInvariance', [], @islogical);
            parser.addParameter('HalfSize', [], @isnumeric);
            parser.parse(varargin{:});
            
            %% Gather parameters   
            fields = fieldnames(parser.Results);
            params = {};
            for f = 1:numel(fields),
                field = fields{f};
                if ~isempty(parser.Results.(field)),
                    params = [ params, field, parser.Results.(field) ];
                end
            end
            
            %% Create implementation
            self.implementation = cv.DescriptorExtractor('LATCH', params{:});
        end
        
        function desc = compute_from_patch (self, I)            
            % LATCH implementation uses 48x48 patch and half_ssd_size of 3,
            % thus it filters out points that are less than 24 + 3 = 27 
            % pixels from the image border. Hence, the patch must be larger 
            % than 54x54 pixels, and we opt to use 56x56.
            
            % Resize to patch size
            I = imresize(I, [ self.patch_size, self.patch_size ]);
            
            % Keypoint position: center of the patch
            [ h, w, ~ ] = size(I);
            keypoint.pt = ([ w, h ] - 1) / 2;
            
            % Keypoint size: make something up (does not matter)
            keypoint.size = size(I, 1) / 2;
            
            % Compute descriptor for the keypoint
            desc = self.compute(I, keypoint);
        end
    end
end