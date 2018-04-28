classdef AffineEvaluation < vicos.experiment.Experiment
    properties
        % Dataset path
        dataset_path
        
        dataset_type
        
        % Back-projection error threshold for determining camera-geometry
        % consistency of a match (in pixels)
        backprojection_threshold
        
        % Distance ratio threshold for putative matches
        putative_match_ratio
        
        % Image border size (for keypoint filtering)
        filter_border
        
        % Global cache directory settings
        cache_dir
                
        % Cache descriptors
        cache_descriptors
        
        % Force experiments on grayscale images
        force_grayscale
        
        % Maximum number of keypoints
        max_keypoints
    end
    
    methods
        function self = AffineEvaluation (varargin)
            parser = inputParser();
            parser.addParameter('dataset_path', '', @ischar);
            parser.addParameter('dataset_name', 'affine', @ischar)
            parser.addParameter('half_size_images', true, @islogical);
            parser.addParameter('backprojection_threshold', 2.5, @isnumeric);
            parser.addParameter('putative_match_ratio', 0.8, @isnumeric);
            parser.addParameter('filter_border', 25, @isnumeric);
            parser.addParameter('cache_dir', '', @ischar);
            parser.addParameter('force_grayscale', false, @islogical);
            parser.addParameter('max_keypoints', inf, @isnumeric);
            parser.addParameter('cache_descriptors', false, @islogical);
            parser.parse(varargin{:});
            
            % Parameters
            self.filter_border = parser.Results.filter_border;
            self.backprojection_threshold = parser.Results.backprojection_threshold;
            self.putative_match_ratio = parser.Results.putative_match_ratio;
            
            self.max_keypoints = parser.Results.max_keypoints;
            
            % Global cache dir
            self.cache_dir = parser.Results.cache_dir;

            self.cache_descriptors = parser.Results.cache_descriptors;

            % Grayscale images
            self.force_grayscale = parser.Results.force_grayscale;
            
            % Store dataset name as type (affine vs hpatches) so that we
            % can support both file-naming schemes
            self.dataset_type = parser.Results.dataset_name;
            
            % Default dataset path            
            self.dataset_path = parser.Results.dataset_path;
            if isempty(self.dataset_path)
                % Dataset folder name
                dataset_name = parser.Results.dataset_name;

                % Determine code root path
                code_root = fileparts(mfilename('fullpath'));
                code_root = fullfile(code_root, '..', '..', '..');
                self.dataset_path = fullfile(code_root, '..', 'datasets', dataset_name);
            end
            
            assert(exist(self.dataset_path, 'dir') ~= 0, 'Invalid dataset root path "%s"!', self.dataset_path);
        end
        
        results = run_experiment (self, keypoint_detector, descriptor_extractor, sequence, varargin)
        
        % List all sequences
        sequences = list_all_sequences (self)
    end
    
    methods (Access = private)
        filename = get_image_filename (self, sequence, img)
        filename = get_homography_filename (self, sequence, img1, img2)
    end
    
    % Image pair retrieval
    methods
        [ I1, I2, H12 ] = get_image_pair (self, sequence, i1, i2)
        [ I1, I2, H12 ] = get_rotated_image (self, sequence, img, angle)
        [ I1, I2, H12 ] = get_scaled_image (self, sequence, img, scale)
        [ I1, I2, H12 ] = get_sheared_image (self, sequence, img, shear_x, shear_y)
    end
    
    methods
        keypoints = detect_keypoints_in_image (self, sequence, image_id, I, keypoint_detector)
            
        [ descriptors, keypoints ] = extract_descriptors_from_keypoints (self, sequence, image_id, I, keypoint_detector, keypoints, descriptor_extractor)
        
        [ match_idx, match_dist, correct_matches, putative_matches ] = evaluate_matches (self, sequence, ref_image_id, test_image, H21, image_size, keypoint_detector, descriptor_extractor, ref_keypoints, ref_descriptors, test_keypoints, test_descriptors)
        
        [ correspondences, valid ] = evaluate_consistent_correspondences (self, sequence, ref_image_id, test_image_id, image_size, H21, keypoint_detector, ref_keypoints, test_keypoints)
    end
end

