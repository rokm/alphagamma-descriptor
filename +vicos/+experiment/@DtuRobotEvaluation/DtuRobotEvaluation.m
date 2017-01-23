classdef DtuRobotEvaluation < handle
    properties
        % Dataset path
        dataset_path
        
        % Camera matrices
        cameras
       
        % Size of cells in structured-light grid (in pixels)
        grid_cell_size
        
        % Back-projection error threshold for determining camera-geometry
        % consistency of a match (in pixels)
        backprojection_threshold
        
        % Bounding box padding when evaluating matches in 3D (in meters)
        bbox_padding_3d
        
        % Scale margin for correspondence consistency check
        scale_margin
        
        % Half-size images in dataset?
        half_size_images
        
        % Distance ratio threshold for putative matches
        putative_match_ratio
        
        % Global cache directory settings
        cache_dir
    end
    
    methods (Static)
        [ keypoints, descriptors ] = extract_features_from_image (image_file, keypoint_detector, descriptor_extractor, cache_file)

        pt3d = reconstruct_point_3d (camera1, camera2, pt1, pt2)
        [ roc, area ] = compute_roc_curve (ratios, correct)
    end
    
    methods (Access = protected)
        load_camera_calibration (self)
    end
    
    
    methods
        function self = DtuRobotEvaluation (varargin)
            parser = inputParser();
            parser.addParameter('dataset_path', '', @ischar);
            parser.addParameter('half_size_images', true, @islogical);
            parser.addParameter('grid_cell_size', 10, @isnumeric);
            parser.addParameter('backprojection_threshold', 2.5, @isnumeric);
            parser.addParameter('bbox_padding_3d', 3e-3, @isnumeric); % 3 mm
            parser.addParameter('scale_margin', 2, @isnumeric); % 2x
            parser.addParameter('putative_match_ratio', 0.8, @isnumeric);
            parser.addParameter('cache_dir', '', @ischar);
            parser.parse(varargin{:});
            
            % Half-size images?
            self.half_size_images = parser.Results.half_size_images;

            % Parameters
            self.grid_cell_size = parser.Results.grid_cell_size;
            self.backprojection_threshold = parser.Results.backprojection_threshold;
            self.bbox_padding_3d = parser.Results.bbox_padding_3d;
            self.scale_margin = parser.Results.scale_margin;
            self.putative_match_ratio = parser.Results.putative_match_ratio;
            
            % Global cache dir
            self.cache_dir = parser.Results.cache_dir;
            
            % Default dataset path
            self.dataset_path = parser.Results.dataset_path;
            if isempty(self.dataset_path)
                % Determine code root path
                code_root = fileparts(mfilename('fullpath'));
                code_root = fullfile(code_root, '..', '..', '..');
                self.dataset_path = fullfile(code_root, '..', 'datasets', 'dtu_robot');
            end
            
            assert(exist(self.dataset_path, 'dir') ~= 0, 'Invalid dataset root path "%s"!', self.dataset_path);
            
            % Load camera calibration
            self.load_camera_calibration();
        end
        
        results = run_experiment (self, experiment_name, keypoint_detector, descriptor_extractor, image_set, varargin)

        grid = generate_structured_light_grid (self, image_set, reference_image)
        [ mu, sigma, valid ] = lookup_point_3d (self, grid, pt2d)

        
        consistent = check_camera_geometry_consistency (self, camera1, camera2, pt1, pt2)
        correct = is_match_consistent (self, grid, camera1, camera2, pt1, pt2)
        
        [ idx, valid ] = get_consistent_correspondences (self, grid, camera1, camera2, ref_point, ref_scale, points, scales)
        
        filename = construct_image_filename (self, image_set, image_number, light_number)
        filename = construct_cache_filename (self, cache_dir, set_number, image_number, light_number, suffix)
    end
end