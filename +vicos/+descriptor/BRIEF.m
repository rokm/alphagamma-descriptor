classdef BRIEF < vicos.descriptor.OpenCvDescriptor
    % BRIEF - OpenCV BRIEF descriptor extractor
    %
    % (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
        
        patch_size = 58
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
            parser.addParameter('Bytes', [], @isnumeric);
            parser.addParameter('UseOrientation', [], @islogical);  
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
            self.implementation = cv.DescriptorExtractor('BriefDescriptorExtractor', params{:});
        end
        
        function desc = compute_from_patch (self, I)            
            % BRIEF implementation uses 48x48 patch and 9x9 smoothing
            % kernel, thus it filters out points that are less than 
            % 24 + 4 = 28 pixels from the image border. Hence, the patch 
            % must be larger than 56x56 pixels, and we opt to use 58x58.
            
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