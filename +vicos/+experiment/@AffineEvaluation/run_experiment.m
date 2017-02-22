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
    %    - cache_dir: cache directory; default: use global cache dir
    %      setting
        
    % Parse arguments
    parser = inputParser();
    parser.addParameter('cache_dir', self.cache_dir, @ischar);
    parser.parse(varargin{:});
    
    cache_root = parser.Results.cache_dir;
    
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
    %if isempty(test_images)
        % All but reference
        test_images = 2:6;
    %end
    
    % Results filename (caching)
    results_file = '';
    if ~isempty(self.cache_dir)
        results_file = sprintf('%s_%s+%s', sequence, keypoint_detector.identifier, descriptor_extractor.identifier);
        results_file = fullfile(self.cache_dir, results_file);
    end
    
    if ~isempty(results_file) && exist(results_file, 'file')
        tmp = load(results_file);
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
        
         fprintf('Processing test image #%d/%d (seq %s, ref %d, test %d)\n', i, numel(test_images), sequence, ref_image, test_image);

         ref_image_id = sprintf('img%d', ref_image);
         test_image_id = sprintf('img%d', test_image);
         
         [ I1, I2, H12 ] = self.get_image_pair(sequence, ref_image, test_image);
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
    end
end