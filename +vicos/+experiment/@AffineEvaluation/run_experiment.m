function results = run_experiment (self, keypoint_detector, descriptor_extractor, sequence, varargin)
    % Input:
    %  - self:
    %  - keypoint_detector: function handle that creates keypoint
    %    detector instance, or a keypoint detector instance
    %  - descriptor_extractor: function handle that creates
    %    descriptor extractor instance, or a descriptor extractor
    %    instance
    %  - sequence: image sequence to perform experiment on.
    %  - varargin: optional key/value pairs
    %    - experiment_type: experiment type (pairs, rotation, scale, shear)
    %    - test_images: vector of test image numbers (if experiment_type is
    %      pairs) or deformation parameter values (i.e., angles for
    %      rotation, scale factors for scale, or shear values for shear)
        
    % Parse arguments
    parser = inputParser();
    parser.addParameter('experiment_type', 'pairs', @ischar);
    parser.addParameter('test_images', [], @isnumeric);
    parser.addParameter('visualize_correct_matches', false, @islogical);
    parser.addParameter('visualization_parameters', {}, @iscell);
    parser.parse(varargin{:});
        
    experiment_type = parser.Results.experiment_type;
    assert(ismember(experiment_type, { 'pairs', 'rotation', 'scale', 'shear' }), 'Invalid experiment type: %s!', experiment_type);
    
    test_images = parser.Results.test_images;
    
    visualize_correct_matches = parser.Results.visualize_correct_matches;
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
        switch experiment_type
            case 'pairs'
                test_images = 2:6; % All but reference
            case 'rotation'
                test_images = -180:5:180; % Rotation angles
            case 'scale'
                test_images = 0.50:0.05:1.50; % Scale factors
            case 'shear'
                test_images = -0.65:0.05:0.65; % Shear factors
            otherwise
                error('Default test images not defined for experiment type: %s!', experiment_type);
        end
    end
    
    % Results filename (caching)
    results_file = '';
    if ~isempty(self.cache_dir)
        if isequal(experiment_type, 'pairs')
            % No prefix for pairs (default) experiment type
            results_file = sprintf('%s_%s+%s', sequence, keypoint_detector.identifier, descriptor_extractor.identifier);
        else
            results_file = sprintf('%s_%s_%s+%s', experiment_type, sequence, keypoint_detector.identifier, descriptor_extractor.identifier);
        end
        results_file = fullfile(self.cache_dir, results_file);
    end
    
    if ~isempty(results_file) && exist(results_file, 'file')
        tmp = load(results_file);
        assert(isequal(tmp.experiment_type, experiment_type), 'Sanity check on results failed!'); % Sanity check
        results = tmp_results;
        return;
    end
    
    %% Pre-allocate results structure
    results = repmat(struct('sequence', [], ...
                            'reference_image', [], ...
                            'test_image', [], ...
                            'num_consistent_matches', [], ...
                            'num_putative_matches', [], ...
                            'num_correct_matches', [], ...
                            'num_consistent_matches_unique', [], ...
                            'num_putative_matches_unique', [], ...
                            'num_correct_matches_unique', [], ...
                            'num_consistent_correspondences', []), 1, numel(test_images));
    
    %% Process all pairs
    for i = 1:numel(test_images)
        ref_image = 1;
        test_image = test_images(i);
        
         fprintf('Processing test image #%d/%d (%s: seq %s, ref %d, test %g)\n', i, numel(test_images), experiment_type, sequence, ref_image, test_image);

         ref_image_id = sprintf('img%d', ref_image);
         
         % Handle different experiment types
         switch experiment_type
             case 'pairs'
                 test_image_id = sprintf('img%d', test_image);
                 [ I1, I2, H12 ] = self.get_image_pair(sequence, ref_image, test_image);
            case 'rotation'
                 test_image_id = sprintf('img%d-rotation%g', ref_image, test_image);
                 [ I1, I2, H12 ] = self.get_rotated_image(sequence, ref_image, test_image);
            case 'scale'
                 test_image_id = sprintf('img%d-scale%g', ref_image, test_image);
                 [ I1, I2, H12 ] = self.get_scaled_image(sequence, ref_image, test_image);
            case 'shear'
                 test_image_id = sprintf('img%d-shear%g-%g', ref_image, test_image, test_image);
                 [ I1, I2, H12 ] = self.get_sheared_image(sequence, ref_image, test_image, test_image);
             otherwise
                 error('Unhandled experiment type: %s!', experiment_type);
         end
         
         H21 = inv(H12); % Invert the projection matrix (image 1 is our reference image, so we need projection into it, not from it)
         
         if self.force_grayscale
             I1 = rgb2gray(I1);
             I2 = rgb2gray(I2);
         end
         
         %% Process reference image
         ref_keypoints_raw = self.detect_keypoints_in_image(sequence, ref_image_id, I1, keypoint_detector);
         [ ref_descriptors, ref_keypoints ] = self.extract_descriptors_from_keypoints(sequence, ref_image_id, I1, keypoint_detector, ref_keypoints_raw, descriptor_extractor);
         
        %% Process test image
        test_keypoints_raw = self.detect_keypoints_in_image(sequence, test_image_id, I2, keypoint_detector); 
        [ test_descriptors, test_keypoints ] = self.extract_descriptors_from_keypoints(sequence, test_image_id, I2, keypoint_detector, test_keypoints_raw, descriptor_extractor);
         
        %% Evaluate matches
        [ match_idx, match_dist, consistent_matches, putative_matches ] = self.evaluate_matches(sequence, ref_image_id, test_image_id, H21, size(I1), keypoint_detector, descriptor_extractor, ref_keypoints, ref_descriptors, test_keypoints, test_descriptors);
         
        %% Evaluate consistent correspondences
        [ consistent_correspondences, valid_correspondences ] = self.evaluate_consistent_correspondences(sequence, ref_image_id, test_image_id, size(I1), H21, keypoint_detector, ref_keypoints_raw, test_keypoints_raw);
        
        % Compute histogram
        num_consistent_correspondences = cellfun(@numel, consistent_correspondences);
        num_consistent_correspondences(~valid_correspondences) = -1;
        
        %% Compute final results
        results(i).sequence = sequence;
        results(i).reference_image = ref_image;
        results(i).test_image = test_image;
 
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
        if visualize_correct_matches
            tikz_output_path = '';
            if ~isempty(self.cache_dir)
                tikz_output_path = fullfile(self.cache_dir, sprintf('%s_%s_%s_%s_%s', sequence, ref_image_id, test_image_id, keypoint_detector.identifier, descriptor_extractor.identifier));
            end
            self.visualize_matches(I1, I2, ref_keypoints, test_keypoints, match_idx, putative_matches, consistent_matches, 'tikz_code_path', tikz_output_path, visualization_parameters{:});
        end
    end
    
    %% Store results
    if ~isempty(results_file)
        save(results_file, '-v7.3', 'results', 'experiment_type');
    end
end