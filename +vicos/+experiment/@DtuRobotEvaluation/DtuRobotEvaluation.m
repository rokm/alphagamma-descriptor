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
        
        % Half-size images in dataset?
        half_size_images
    end
    
    methods (Static)
        pt3d = reconstruct_point_3d (camera1, camera2, pt1, pt2)
        [ roc, area ] = compute_roc_curve (ratios, correct)
    end
    
    
    methods
        function self = DtuRobotEvaluation (varargin)
            parser = inputParser();
            parser.addParameter('dataset_path', '', @ischar);
            parser.addParameter('half_size_images', true, @islogical);
            parser.addParameter('grid_cell_size', 10, @isnumeric);
            parser.addParameter('backprojection_threshold', 2.5, @isnumeric);
            parser.addParameter('bbox_padding_3d', 3e-3, @isnumeric); % 3 mm
            parser.parse(varargin{:});
            
            % Half-size images?
            self.half_size_images = parser.Results.half_size_images;

            % Parameters
            self.grid_cell_size = parser.Results.grid_cell_size;
            self.backprojection_threshold = parser.Results.backprojection_threshold;
            self.bbox_padding_3d = parser.Results.bbox_padding_3d;
            
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
        
        function load_camera_calibration (self)
            % LOAD_CAMERA_CALIBRATION (self)
            %
            % Load camera calibration from dataset.
            
            % Camera calibration file
            calibration_file = fullfile(self.dataset_path, 'Calib_Results_11.mat');
            assert(exist(calibration_file, 'file') ~= 0, 'Camera calibration "%s" not found!', calibration_file);
            
            % Load
            tmp = load(calibration_file);
            
            % Pre-allocate camera matrices
            num_cameras = 119;
            self.cameras = zeros(3, 4, num_cameras);
            
            % Scale matrix
            if self.half_size_images
                S = [ 0.5,   0, 0;
                        0, 0.5, 0;
                        0,   0, 1 ];
            else
                S = eye(3);
            end
            
            % Load cameras
            K = [ tmp.fc(1),         0, tmp.cc(1);
                          0, tmp.fc(2), tmp.cc(2);
                          0,         0,         1 ];
            
            for i = 1:num_cameras
                R = tmp.(sprintf('Rc_%d', i));
                T = tmp.(sprintf('Tc_%d', i));
                
                self.cameras(:,:,i) = S * K * [ R, T ];
            end
        end
        
        function grid = generate_structured_light_grid (self, image_set, reference_image)
            % grid = GENERATE_STRUCTURED_LIGHT_GRID (self, image_set, reference_image)
            %
            % Generates the projection of structured-light grid (i.e.,
            % ground truth points) and grids them into a two-level quad
            % tree for faster lookup.
            %
            % This function is equivalent to GenStrLightGrid_v2() from DTU
            % Robot Evaluation Code (except the rows and columns of the
            % quad tree correspond to dimensions of image).
            %
            % Input:
            %  - self:
            %  - image_set:
            %  - reference_image:
            %
            % Output:
            %  - grid: resulting lookup grid structure
            %     - pts: 5xN matrix of points (2D and 3D coordinates)
            %     - grid3d: indices
            
            % Image dimensions
            image_width = 1600;
            image_height = 1200;
            if self.half_size_images
                image_width = image_width / 2;
                image_height = image_height / 2;
            end
            
            % Load data file
            data_file = fullfile(self.dataset_path, 'CleanRecon_2009_11_16', sprintf('Clean_Reconstruction_%02d.mat', image_set));
            assert(exist(data_file, 'file') ~= 0, 'Structured-light data file "%s" does not exist!', data_file);
            
            data = load(data_file);
            
            % Gather 3-D points
            pts3d = [ data.pts3D_near(1:3,:), data.pts3D_far(1:3,:) ];
            
            % Project to reference image
            pts2d = self.cameras(:,:,reference_image) * [ pts3d; ones(1, size(pts3d, 2)) ];
            pts2d = bsxfun(@rdivide, pts2d(1:2,:), pts2d(3,:));
            
            % Merge points
            pts = [ pts2d; pts3d ];
            
            % Generate grid
            grid_rows = ceil(image_height / self.grid_cell_size);
            grid_cols = ceil(image_width / self.grid_cell_size);
            
            grid3d = cell(grid_rows, grid_cols);
            
            for i = 1:size(pts, 2)
                x = pts(1,i);
                y = pts(2,i);
                
                % Is projection inside the image?
                if x > 0 && x < image_width && y > 0 && y < image_height
                    % Column and row
                    c = ceil(x / self.grid_cell_size); 
                    r = ceil(y / self.grid_cell_size);
                    
                    % Append index
                    grid3d{r,c}(end+1) = i;
                end
            end
            
            % Store results
            grid.pts = pts;
            grid.grid3d = grid3d;            
        end
        
        function [ mu, sigma, valid ] = lookup_point_3d (self, grid, pt2d)
            % [ mu, sigma, valid ] = LOOKUP_POINT_3D (self, grid, pt2d)
            %
            % Looks up a 2-D point in the quad-tree of structured-light 3-D
            % point projections, which was previously obtained by a call
            % to GENERATE_STRUCTURED_LIGHT_GRID(). The 2-D point
            % coordinates must be from the image for which the quad-tree
            % was generated (i.e., the reference image).
            %
            % This function projects the point into grid, looks up 3D
            % coordinates of all neighbouring points, and computes the
            % mean and variance of 3-D coordinates for all points inside
            % the search radius (i.e., cell size).
            %
            % This function is equivalent to Get3DGridEst() from DTU
            % Robot Evaluation Code.
            %
            % Input:
            %  - self:
            %  - grid: quad-tree structure of structured-light 3-D point
            %    projections, obtained by GENERATE_STRUCTURED_LIGHT_GRID()
            %  - pt2d: 2x1 vector of 2-D point coordinates
            %
            % Output:
            %  - mu: 3x1 vector of mean 3-D coordinates
            %  - sigma: 3x1 vector of max deviations for 3-D coordinates
            %  - valid: validity flag (false if point falls outside the
            %    quad tree)
                        
            % Grid column and row
            c = ceil(pt2d(1) / self.grid_cell_size);
            r = ceil(pt2d(2) / self.grid_cell_size);
            
            if r < 1 || r > size(grid.grid3d, 1) || c < 1 || c > size(grid.grid3d, 2)
                valid = false;
                mu = nan;
                sigma = nan;
                return;
            end
            
            % Gather 3-D coordinates of the neighbouring points
            pts3d = zeros(3, 0);
            
            for i = -1:1
                for j = -1:1
                    r2 = r + i;
                    c2 = c + j;
                    
                    % Validate cell coordinates
                    if r2 < 1 || r2 > size(grid.grid3d, 1) || c2 < 1 || c2 > size(grid.grid3d, 2)
                        continue;
                    end
                    
                    % Check all points
                    indices = grid.grid3d{r2, c2};
                    for k = 1:numel(indices)
                        idx = indices(k);
                        
                        % If 2-D coordinates of a structured-light points
                        % are close enough to our 2-D point, append the
                        % corresponding 3-D coordinates to list.
                        if norm(grid.pts(1:2,idx) - pt2d) <= self.grid_cell_size
                            pts3d(:, end+1) = grid.pts(3:5,idx); %#ok<AGROW>
                        end
                    end
                end
            end
            
            % No matches?
            if isempty(pts3d)
                valid = false;
                mu = nan;
                sigma = nan;
                return;
            end
            
            valid = true;
            
            % A single point ?
            if size(pts3d, 2) == 1
                mu = pts3d;
                sigma = zeros(3, 1);
                return;
            end
            
            mu = mean(pts3d, 2);
            sigma = max(abs(bsxfun(@minus, pts3d, mu)), [], 2);
        end
        
        
        function consistent = check_camera_geometry_consistency (self, camera1, camera2, pt1, pt2)
            % consistent = CHECK_CAMERA_GEOMETRY_CONSISTENCY (self, camera1, camera2, pt1, pt2)
            %
            % Checks if the pair of correspondences from two cameras is
            % consistent with geometry of the corresponding cameras. From
            % the given pair of 2-D image points, a 3-D point is
            % reconstructed, and back-projected to both cameras; the pair
            % is consistent if reprojection error is smaller than the
            % specified tolerance.
            %
            % This function is equivalent to IsPointCamGeoConsistent() from
            % DTU Robot Evaluation Code.
            %
            % Input:
            %  - self:
            %  - camera1: 3x4 projective matrix for first camera
            %  - camera2: 3x4 projective matrix for second camera
            %  - pt1: 1x2 vector with image coordinates in first image
            %  - pt2: 1x2 vector with image coordinates in second image
            %
            % Output:
            %  - consistent: a boolean flag indicating whether the pair is
            %    consistent with camera-pair geometry or not
            
            % Reconstruct the 3-D point
            pt3d = self.reconstruct_point_3d(camera1, camera2, pt1, pt2);
            
            % Back-project
            pt2d1 = camera1 * [ pt3d; 1 ];
            pt2d1 = pt2d1(1:2) / pt2d1(3);
            
            pt2d2 = camera2 * [ pt3d; 1 ];
            pt2d2 = pt2d2(1:2) / pt2d2(3);
            
            % Back-projection error
            err = norm(pt2d1 - pt1) + norm(pt2d2 - pt2);
            
            % Consistency
            consistent = err < self.backprojection_threshold;
        end
        
        function correct = is_match_consistent (self, grid, camera1, camera2, pt1, pt2)
            % correct = IS_MATCH_CONSISTENT (self, grid, camera1, camera2, pt1, pt2)
            %
            % Evaluates consistency of a keypoint pair from two images.
            % The first image is expected to be the reference one, i.e.,
            % the one for which the quad tree of structured-light point
            % projections is given.
            %
            % This function is equivalent to IsMatchConsistent() from DTU
            % Robot Evaluation Code.
            %
            % Input:
            %  - self:
            %  - grid: quad-tree structure of structured-light 3-D point
            %  - camera1: 3x4 projective matrix for first camera
            %  - camera2: 3x4 projective matrix for second camera
            %  - pt1: 1x2 vector with image coordinates in first image
            %  - pt2: 1x2 vector with image coordinates in second image
            %
            % Output:
            %  - correct: a value indicating whether the match is correct
            %    (1), incorrect (-1), or could not be estimated because the
            %    point could not be matched to structured-light
            %    ground-truth points in the reference image (0)
            
            % Look up the point from the reference image in the 
            % structured-light quad tree
            [ mu, sigma, valid ] = self.lookup_point_3d(grid, pt1);
            if ~valid
                correct = 0; % Cannot evaluate the correctness
                return;
            end
            
            % Create a bounding box with applied padding
            sigma = sigma + self.bbox_padding_3d;
            pts3d = mu*ones(1, 8) + [ sigma(1)*[ -1,  1, -1,  1, -1,  1, -1, 1 ];
                                      sigma(2)*[ -1, -1,  1,  1, -1, -1,  1, 1 ];
                                      sigma(3)*[ -1, -1, -1, -1,  1,  1,  1, 1 ] ]; % Eight bounding box corners
            
            % Project bounding box to second image
            pts2d = camera2 * [ pts3d; ones(1, size(pts3d, 2)) ];
            pts2d = bsxfun(@rdivide, pts2d(1:2,:), pts2d(3,:));

            % Bounding box
            xmin = min(pts2d(1, :));
            xmax = max(pts2d(1, :));
            ymin = min(pts2d(2, :));
            ymax = max(pts2d(2, :));
            
            if pt2(1) > xmin && pt2(1) < xmax && pt2(2) > ymin && pt2(2) < ymax
                % Validate camera-geometry consistency
                if self.check_camera_geometry_consistency(camera1, camera2, pt1, pt2),
                    correct = 1;
                else
                    correct = -1;
                end
            else
                correct = -1;
            end
        end
        
        function run_experiment (self, experiment_name, keypoint_detector, descriptor_extractor, image_set, varargin)
            % Input:
            %  - self:
            %  - experiment_name: name of experiment
            %  - keypoint_detector: function handle that creates keypoint
            %    detector instance, or a keypoint detector instance
            %  - descriptor_extractor: function handle that creates
            %    descriptor extractor instance, or a descriptor extractor
            %    instance
            %  - varargin: optional key/value pairs
            %    - cache_dir: cache directory; default: disabled
            %    - reference_image: reference/key image to which all others
            %     are compared (default: 25)
            %    - test_images: list of test images; default: all (1~119)
            %    - light_number: number of light preset to use; default: 8
            
            parser = inputParser();
            parser.addParameter('reference_image', 25, @isnumeric);
            parser.addParameter('test_images', [], @isnumeric);
            parser.addParameter('light_number', 8, @isnumeric);
            parser.addParameter('cache_dir', '', @ischar);
            parser.parse(varargin{:});
            
            reference_image = parser.Results.reference_image;
            test_images = parser.Results.test_images;
            light_number = parser.Results.light_number;
            cache_dir = parser.Results.cache_dir;

            % Keypoint detector
            if isa(keypoint_detector, 'function_handle')
                keypoint_detector = keypoint_detector();
            end
            assert(isa(keypoint_detector, 'vicos.keypoint_detector.KeypointDetector'), 'Invalid keypoint detector!');
            
            % Descriptor extractor
            if isa(descriptor_extractor, 'function_handle')
                descriptor_extractor = descriptor_extractor();
            end
            assert(isa(descriptor_extractor, 'vicos.descriptor.Descriptor'), 'Invalid descriptor extractor!');
            
            % Default test images
            if isempty(test_images)
                % All but reference
                test_images = setdiff(1:size(self.cameras, 3), reference_image);
            end
            
            %% Cache directory
            if ~isempty(cache_dir)
                cache_dir = fullfile(cache_dir, experiment_name);
                if ~exist(cache_dir, 'dir')
                    mkdir(cache_dir);
                end
            end
            
            %% Prepare
            % Pre-compute the quad tree of projected structured-light
            % points, which serves as ground-truth for evaluation
            quad3d = self.generate_structured_light_grid(image_set, reference_image);
            
            % Default cache file (empty)
            cache_file = '';
            
            %% Process reference image
            image_file_ref = self.construct_image_filename(image_set, reference_image, light_number);
            fprintf('Processing reference image (seq #%03d, img #%03d, light #%02d)\n', image_set, reference_image, light_number);
            if ~isempty(cache_dir)
                cache_file = self.construct_cache_filename(cache_dir, image_set, reference_image, light_number, '.features.mat');
            end
            
            [ ref_keypoints, ref_descriptors ] = self.extract_features_from_image(image_file_ref, keypoint_detector, descriptor_extractor, cache_file);
            camera_ref = self.cameras(:,:,reference_image);
                        
            %% Process all test images
            for i = 1:numel(test_images)
                test_image = test_images(i);
                
                %% Process test image
                image_file = self.construct_image_filename(image_set, test_image, light_number);
                fprintf('Processing test image #%d/%d (seq #%03d, img #%03d, light #%02d)\n', i, numel(test_images), image_set, test_image, light_number);
                if ~isempty(cache_dir)
                    cache_file = self.construct_cache_filename(cache_dir, image_set, test_image, light_number, '.features.mat');
                end
                [ test_keypoints, test_descriptors ] = self.extract_features_from_image(image_file, keypoint_detector, descriptor_extractor, cache_file);
                
                %% Camera for test image
                camera = self.cameras(:,:,test_image);


                %% Evaluate
                fprintf('Evaluating pair #%d/#%d\n', test_image, reference_image);
                                
                keypoint_offset = 1; % C indexing to Matlab indexing
                if self.half_size_images
                    keypoint_offset = keypoint_offset + 0.5; % Additional offset due to downscaling
                end
                
                % Compute descriptor distance matrix
                M = descriptor_extractor.compute_pairwise_distances(ref_descriptors, test_descriptors);
                
                % For each test keypoint (row in M), find the closest match
                Mm = M;
                [ min_dist1, min_idx1 ]  = min(Mm, [], 2); % For each test keypoint, find the closest match 
                
                % Find the next closest match (by masking the closest one)
                cidx = sub2ind(size(Mm), [ 1:numel(min_idx1) ]', min_idx1);
                Mm(cidx) = inf;
                [ min_dist2, min_idx2 ] = min(Mm, [], 2);
                
                % Prepare the match structure (as specified by the DTU
                % code)
                clear match;
                
                match.matchIdx = [ min_idx1, min_idx2 ]; % Indices to first and second closest match in reference image
                match.dist = [ min_dist1, min_dist2 ]; % Distances to first and second closest match in reference image
                match.distRatio = min_dist1 ./ min_dist2; % Distance ratio
                match.coord = vertcat(test_keypoints.pt) + keypoint_offset; % Coordinates of keypoints in test image
                match.coordKey = vertcat(ref_keypoints.pt) + keypoint_offset; % Coordinates of keypoints in reference image
                tmp_area = 1./(vertcat(test_keypoints.size)*0.5).^2; % [ a, b, c ] parameters of ellipse approximation for keypoints in test image -> [ r, 0, r ]
                match.area = [ tmp_area, zeros(size(tmp_area)), tmp_area ]; 
                tmp_area = 1./(vertcat(ref_keypoints.size)*0.5).^2; % [ a, b, c ] parameters of ellipse approximation for keypoints in test image -> [ r, 0, r ]
                match.areaKey = [ tmp_area, zeros(size(tmp_area)), tmp_area ]; 
                
                % Determine geometric consistency of matches (-1 =
                % inconsistent, 1 = consistent, 0 = could not be evaluated)
                match.CorrectMatch = zeros(size(match.coord,1), 1);
                for j = 1:size(match.coord,1)
                    % Get the coordinates of the matched pair from the match structure.
                    pt2 = match.coord(j,:);
                    pt1 = match.coordKey(match.matchIdx(j,1),:);

                    % Determine if the match is consistent.
                    match.CorrectMatch(j) = self.is_match_consistent(quad3d, camera_ref, camera, pt1', pt2');
                end

                % Compute the ROC curve
                [ roc, area ] = self.compute_roc_curve(match.distRatio, match.CorrectMatch);
                
                %% Compute final results
                
                %% Visualize
                %Ir = imread(image_file_ref);
                %I  = imread(image_file);
                
                
            end
        end
        
        
        
        
            
        function [ keypoints, descriptors ] = extract_features_from_image (self, image_file, keypoint_detector, descriptor_extractor, cache_file)
            % [ keypoints, descriptors ] = EXTRACT_FEATURES_FROM_IMAGE (self, image_file, keypoint_detector, descriptor_extractor, cache_file)
            %
            % Computes keypoints and extracts descriptors from the image.
            % Optionally, if cache filename is provided, it attempts to
            % load cached results, or stores the results to the cache file
            % for later re-use.
            %
            % Input:
            %  - self:
            %  - image_file: full path to input image
            %  - keypoint_detector: instance of keypoint detector (i.e., a
            %    @vicos.keypoint_detector.Detector)
            %  - descriptor_extractor: instance of descriptor extractor
            %    (i.e., a @vicos.descriptor.Descriptor)
            %  - cache_file: optional cache filename; if provided, 
            %
            % Output:
            %  - keypoints: 1xN array of OpenCV keypoint structures
            %  - descriptors: NxD array of corresponding descriptors
            
            % Load from cache, if available
            if ~isempty(cache_file) && exist(cache_file, 'file'),
                tmp = load(cache_file);
                keypoints = tmp.keypoints;
                descriptors = tmp.descriptors;
                return;
            end
            
            % Load image
            I = imread(image_file);
            
            % Detect keypoints
            t = tic();
            keypoints = keypoint_detector.detect(I);
            time_keypoints = toc(t);
            
            % Extract descriptors
            t = tic();
            [ descriptors, keypoints ] = descriptor_extractor.compute(I, keypoints);
            time_descriptors = toc(t);
            
            % Save to cache
            if ~isempty(cache_file),
                vicos.utils.ensure_path_exists(cache_file);
                tmp = struct('keypoints', keypoints, 'time_keypoints', time_keypoints, 'descriptors', descriptors, 'time_descriptors', time_descriptors); %#ok<NASGU>
                save(cache_file, '-v7.3', '-struct', 'tmp');
            end
        end
    end
    
    
    methods
        function filename = construct_image_filename (self, image_set, image_number, light_number)
            % filename = CONSTRUCT_IMAGE_FILENAME (self, set_number, image_number, light_number)
            %
            % Constructs image filename, given the set (sequence) number,
            % image number in the sequence, and lighting preset number.
            %
            % Input:
            %  - self:
            %  - image_set: image set (sequence)
            %  - image_number: image number
            %  - light_number: light preset number
            %
            % Output:
            %  - filename: image filename
            
            image_dir = sprintf('SET%03d', image_set);
            image_name = sprintf('Img%03d_%02d.bmp', image_number, light_number);
            
            filename = fullfile(self.dataset_path, image_dir, image_name);
        end
        
        function filename = construct_cache_filename (self, cache_dir, set_number, image_number, light_number, suffix)
            % filename = CONSTRUCT_CACHE_FILENAME (self, cache_dir, set_number, image_number, light_number, suffix)
            %
            % Constructs cache filename, given the set (sequence) number,
            % image number in the sequence, and lighting preset number.
            %
            % Input:
            %  - self:
            %  - cache_dir: cache directory
            %  - image_set: image set (sequence)
            %  - image_number: image number
            %  - light_number: light preset number
            %  - suffix: optional suffix to append to the basename
            %
            % Output:
            %  - filename: image filename
            
            % Default suffix
            if ~exist('suffix', 'var'),
                suffix = '';
            end
            
            % Construct basename
            basename = sprintf('SET%03d_Img%03d_%02d', set_number, image_number, light_number);
            
            % Construct full filename
            filename = fullfile(cache_dir, [ basename, suffix ]);
        end
    end
end