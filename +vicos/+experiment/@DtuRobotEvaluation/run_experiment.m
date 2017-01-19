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
