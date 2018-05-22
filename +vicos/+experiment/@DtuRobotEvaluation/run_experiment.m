function results = run_experiment (self, keypoint_detector, descriptor_extractor, image_set, varargin)
    % Input:
    %  - self:
    %  - keypoint_detector: function handle that creates keypoint
    %    detector instance, or a keypoint detector instance
    %  - descriptor_extractor: function handle that creates
    %    descriptor extractor instance, or a descriptor extractor
    %    instance
    %  - image_set: image set to perform experiment on.
    %  - varargin: optional key/value pairs
    %    - reference_image: reference/key image to which all others
    %     are compared (default: 25)
    %    - test_images: list of test images; default: all (1~119)
    %    - light_number: number of light preset to use; default: 8
        
    % Parse arguments
    parser = inputParser();
    parser.addParameter('reference_image', 25, @isnumeric);
    parser.addParameter('test_images', [], @isnumeric);
    parser.addParameter('light_number', 8, @isnumeric);
    parser.addParameter('visualize_matches', false, @islogical);
    parser.addParameter('visualization_parameters', {}, @iscell);
    parser.parse(varargin{:});
    
    ref_image = parser.Results.reference_image;
    test_images = parser.Results.test_images;
    light_number = parser.Results.light_number;
    visualize_matches = parser.Results.visualize_matches;
    visualization_parameters = parser.Results.visualization_parameters;
    
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
        test_images = setdiff(1:size(self.cameras, 3), ref_image);
    end
    
    % Results filename (caching)
    results_file = '';
    if ~isempty(self.cache_dir)
        results_file = sprintf('SET%03d_%s+%s.mat', image_set, keypoint_detector.identifier, descriptor_extractor.identifier);
        results_file = fullfile(self.cache_dir, results_file);
    end
    
    if ~isempty(results_file) && exist(results_file, 'file')
        tmp = load(results_file);
        results = tmp.results;
        return;
    end
    
    
    %% Prepare
    % Pre-compute the quad tree of projected structured-light
    % points, which serves as ground-truth for evaluation
    quad3d = self.generate_structured_light_grid(image_set, ref_image);
        
    %% Process reference image   
    fprintf('Processing reference image (seq #%03d, img #%03d, light #%02d)\n', image_set, ref_image, light_number);
    
    % Detect keypoints
    Ir = [];
    [ ref_keypoints_raw, Ir ] = self.detect_keypoints_in_image(image_set, ref_image, light_number, Ir, keypoint_detector);
    
    % Extract descriptors
    [ ref_descriptors, ref_keypoints ] = self.extract_descriptors_from_keypoints(image_set, ref_image, light_number, Ir, keypoint_detector, ref_keypoints_raw, descriptor_extractor);
        
    %% Pre-allocate results structure
    results = repmat(struct('sequence', [], ...
                            'lighting', [], ...
                            'reference_image', [], ...
                            'test_image', [], ...
                            'num_keypoints_in_ref', [], ...
                            'num_keypoints_out_ref', [], ...
                            'num_keypoints_in_test', [], ...
                            'num_keypoints_out_test', [], ...
                            'num_consistent_matches', [], ...
                            'num_putative_matches', [], ...
                            'num_correct_matches', [], ...
                            'num_keypoints_in_ref_unique', [], ...
                            'num_keypoints_out_ref_unique', [], ...
                            'num_keypoints_in_test_unique', [], ...
                            'num_keypoints_out_test_unique', [], ...
                            'num_consistent_matches_unique', [], ...
                            'num_putative_matches_unique', [], ...
                            'num_correct_matches_unique', [], ...
                            'num_consistent_correspondences', []), 1, numel(test_images));
    
    %% Process all test images
    for i = 1:numel(test_images)
        test_image = test_images(i);
        
        fprintf('Processing test image #%d/%d (seq #%03d, img #%03d, light #%02d)\n', i, numel(test_images), image_set, test_image, light_number);
        
        %% Process test image
        % Detect keypoints
        It = [];
        [ test_keypoints_raw, It ] = self.detect_keypoints_in_image(image_set, test_image, light_number, It, keypoint_detector);

        % Extract descriptors
        [ test_descriptors, test_keypoints ] = self.extract_descriptors_from_keypoints(image_set, test_image, light_number, It, keypoint_detector, test_keypoints_raw, descriptor_extractor);
        
        %% Evaluate consistent correspondences
        % Note: the results are cached on per-keypoint detector level (i.e,
        % the value is cached across all descriptors extracted from the
        % given keypoint type)
        fprintf('Evaluating consistent correspondences for pair #%d|#%d\n', test_image, ref_image);
        [ consistent_correspondences, valid_correspondences ] = self.evaluate_consistent_correspondences(image_set, ref_image, test_image, light_number, quad3d, keypoint_detector, ref_keypoints_raw, test_keypoints_raw);
        
        % Compute histogram
        num_consistent_correspondences = cellfun(@numel, consistent_correspondences);
        num_consistent_correspondences(~valid_correspondences) = -1;
        
        %% Evaluate putative and correct matches
        [ match_idx, match_dist, consistent_matches, putative_matches ] = self.evaluate_matches(image_set, ref_image, test_image, light_number, quad3d, keypoint_detector, descriptor_extractor, ref_keypoints, ref_descriptors, test_keypoints, test_descriptors);
        [ roc, area ] = self.compute_roc_curve(match_dist(:,1)./match_dist(:,2), consistent_matches);

        %% FIXME: visualization
        
        %% Compute final results
        results(i).sequence = image_set;
        results(i).lighting = light_number;
        results(i).reference_image = ref_image;
        results(i).test_image = test_image;
        
        % Number of keypoints
        results(i).num_keypoints_in_ref = numel(ref_keypoints_raw);
        results(i).num_keypoints_out_ref = numel(ref_keypoints);
        
        results(i).num_keypoints_in_test = numel(test_keypoints_raw);
        results(i).num_keypoints_out_test = numel(test_keypoints);

        % Number of unique keypoints
        results(i).num_keypoints_in_ref_unique = vicos.utils.count_unique_keypoints(ref_keypoints_raw);
        results(i).num_keypoints_out_ref_unique = vicos.utils.count_unique_keypoints(ref_keypoints);
        
        results(i).num_keypoints_in_test_unique = vicos.utils.count_unique_keypoints(test_keypoints_raw);
        results(i).num_keypoints_out_test_unique = vicos.utils.count_unique_keypoints(test_keypoints);
        
        % Matches
        results(i).num_consistent_matches = sum(consistent_matches == 1); % Number of geometrically-consistent matches
        results(i).num_putative_matches = sum(putative_matches); % Number of putative matches
        results(i).num_correct_matches = sum((consistent_matches == 1) & putative_matches); % Correct matches: putative matches that are geometrically consistent
        
        % Construct the cell array of coordinate and size pairings, used to
        % filter out duplicates
        test_xy = vertcat(test_keypoints.pt);
        test_size = vertcat(test_keypoints.size);
        ref_xy = vertcat(ref_keypoints.pt);
        ref_size = vertcat(ref_keypoints.size);
        
        pairings = [ test_xy, test_size, ref_xy(match_idx(:,1),:), ref_size(match_idx(:,1),:) ];
        
        tmp = unique(pairings(consistent_matches == 1,:), 'rows'); % Unique geometrically-consistent matches
        results(i).num_consistent_matches_unique = size(tmp, 1 );
        
        tmp = unique(pairings(putative_matches,:), 'rows'); % Unique putative matches
        results(i).num_putative_matches_unique = size(tmp, 1 );
        
        tmp = unique(pairings((consistent_matches == 1) & putative_matches,:), 'rows'); % Unique correct matches
        results(i).num_correct_matches_unique = size(tmp, 1 );
           
        % Number of consistent correspondences (at least one
        % geometrically-consistent match)
        results(i).num_consistent_correspondences = sum(num_consistent_correspondences >= 1);

        %% Visualization of matches
        if visualize_matches
            tikz_output_path = '';
            if ~isempty(self.cache_dir)
                tikz_output_path = fullfile(self.cache_dir, sprintf('SET%03d_Img%03d_%02d_Img%03d_%02d_%s_%s', image_set, ref_image, light_number, test_image, light_number, keypoint_detector.identifier, descriptor_extractor.identifier));
            end
            % Always load images
            Ir_ = imread(self.construct_image_filename(image_set, ref_image, light_number));
            It_ = imread(self.construct_image_filename(image_set, test_image, light_number));
            self.visualize_matches(Ir_, It_, ref_keypoints, test_keypoints, match_idx, putative_matches, consistent_matches, 'tikz_code_path', tikz_output_path, visualization_parameters{:});
        end
    end
    
    %% Store results
    if ~isempty(results_file)
        save(results_file, '-v7.3', 'results');
    end
end
