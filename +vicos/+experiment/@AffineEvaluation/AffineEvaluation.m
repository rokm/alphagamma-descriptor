classdef AffineEvaluation < handle
    properties
        % Dataset path
        dataset_path
        
        % Back-projection error threshold for determining camera-geometry
        % consistency of a match (in pixels)
        backprojection_threshold
        
        % Distance ratio threshold for putative matches
        putative_match_ratio
        
        % Image border size (for keypoint filtering)
        filter_border
        
        % Global cache directory settings
        cache_dir
    end
    
    methods
        function self = AffineEvaluation (varargin)
            parser = inputParser();
            parser.addParameter('dataset_path', '', @ischar);
            parser.addParameter('half_size_images', true, @islogical);
            parser.addParameter('backprojection_threshold', 5, @isnumeric);
            parser.addParameter('putative_match_ratio', 0.8, @isnumeric);
            parser.addParameter('filter_border', 25, @isnumeric);
            parser.addParameter('cache_dir', '', @ischar);
            parser.parse(varargin{:});
            
            % Parameters
            self.filter_border = parser.Results.filter_border;
            self.backprojection_threshold = parser.Results.backprojection_threshold;
            self.putative_match_ratio = parser.Results.putative_match_ratio;
            
            % Global cache dir
            self.cache_dir = parser.Results.cache_dir;
            
            % Default dataset path
            self.dataset_path = parser.Results.dataset_path;
            if isempty(self.dataset_path)
                % Determine code root path
                code_root = fileparts(mfilename('fullpath'));
                code_root = fullfile(code_root, '..', '..', '..');
                self.dataset_path = fullfile(code_root, '..', 'datasets', 'affine');
            end
            
            assert(exist(self.dataset_path, 'dir') ~= 0, 'Invalid dataset root path "%s"!', self.dataset_path);
        end
    end
    
    % Image pair retrieval
    methods
        [ I1, I2, H12 ] = get_image_pair (self, sequence, i1, i2)
        [ I1, I2, H12 ] = get_rotated_image (self, sequence, img, angle)
        [ I1, I2, H12 ] = get_scaled_image (self, sequence, img, scale)
        [ I1, I2, H12 ] = get_sheared_image (self, sequence, img, shear_x, shear_y)

    end
    
end

