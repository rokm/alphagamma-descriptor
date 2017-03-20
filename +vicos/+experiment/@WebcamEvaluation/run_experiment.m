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
        
    % Parse arguments
    parser = inputParser();
    parser.addParameter('reference_image', '', @ischar);
    parser.addParameter('test_images', {}, @iscell);
    parser.addParameter('visualize_matches', false, @islogical);
    parser.parse(varargin{:});
    
    ref_image = parser.Results.reference_image;
    test_images = parser.Results.test_images;
    visualize_matches = parser.Results.visualize_matches;
    
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
    
    % List all images in requested sequence
    sequence_dir = fullfile(self.dataset_path, sequence);
    assert(exist(sequence_dir, 'dir') ~= 0, 'Invalid sequence name "%s"; folder "%s" does not exist!', sequence, sequence_dir);
    
    sequence_dir = fullfile(sequence_dir, 'test', 'image_color');
    
    all_images = dir(fullfile(sequence_dir, '*.png'));
    all_images = {all_images.name };
    
    % Reference image
    if isempty(ref_image)
        switch sequence
            case 'Frankfurt'
                ref_image = '20131230_142421.png';
            otherwise
                ref_image = all_images{1};
                warning('Reference image undefined; taking first image as reference: %s', ref_image);
        end
        
        % Validate reference image
        assert(ismember(ref_image, all_images), 'Invalid reference image; requested name not found among listed images!');
    end
    
    % Default test images
    if isempty(test_images)
        test_images = setdiff(all_images, ref_image);
    else
        assert(all(ismember(test_images, all_images)), 'One or more specified test images are invalid!');
    end
    
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
    
    %% Process reference image
    [ ~, ref_image_id ] = fileparts(ref_image); % Strip suffix
    
    Ir_ = imread(fullfile(sequence_dir, ref_image));
    if self.force_grayscale
        Ir = rgb2gray(Ir_);
    else
        Ir = Ir_;
    end
    
    ref_keypoints_raw = self.detect_keypoints_in_image(sequence, ref_image_id, Ir, keypoint_detector);
    [ ref_descriptors, ref_keypoints ] = self.extract_descriptors_from_keypoints(sequence, ref_image_id, Ir, keypoint_detector, ref_keypoints_raw, descriptor_extractor);
                        
    %% Process all test images
    for i = 1:numel(test_images)
        test_image = test_images{i};
        
         fprintf('Processing test image #%d/%d (seq %s, ref %s, test %s)\n', i, numel(test_images), sequence, ref_image, test_image);

         [ ~, test_image_id ] = fileparts(test_image); % Strip suffix
         
         It_ = imread(fullfile(sequence_dir, test_image));
         if self.force_grayscale
             It = rgb2gray(It_);
         else
             It = It_;
         end
         
         H21 = eye(3); % As we are using the AffineExperiment framework, we need transformation matrix, which is identity
         
        %% Process test image
        test_keypoints_raw = self.detect_keypoints_in_image(sequence, test_image_id, It, keypoint_detector); 
        [ test_descriptors, test_keypoints ] = self.extract_descriptors_from_keypoints(sequence, test_image_id, It, keypoint_detector, test_keypoints_raw, descriptor_extractor);
         
        %% Evaluate matches
        [ match_idx, match_dist, consistent_matches, putative_matches ] = self.evaluate_matches(sequence, ref_image_id, test_image_id, H21, size(Ir), keypoint_detector, descriptor_extractor, ref_keypoints, ref_descriptors, test_keypoints, test_descriptors);
         
        %% Evaluate consistent correspondences
        [ consistent_correspondences, valid_correspondences ] = self.evaluate_consistent_correspondences(sequence, ref_image_id, test_image_id, size(Ir), H21, keypoint_detector, ref_keypoints_raw, test_keypoints_raw);
        
        % Compute histogram
        num_consistent_correspondences = cellfun(@numel, consistent_correspondences);
        num_consistent_correspondences(~valid_correspondences) = -1;
        
        %% Compute final results
        results(i).sequence = sequence;
        results(i).reference_image = ref_image_id;
        results(i).test_image = test_image_id;
 
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
                tikz_output_path = fullfile(self.cache_dir, sprintf('%s_%s_%s_%s_%s', sequence, ref_image_id, test_image_id, keypoint_detector.identifier, descriptor_extractor.identifier));
            end
            self.visualize_matches(Ir_, It_, ref_keypoints, test_keypoints, match_idx, putative_matches, consistent_matches, 'tikz_code_path', tikz_output_path);
        end
    end
    
    %% Store results
    if ~isempty(results_file)
        save(results_file, '-v7.3', 'results');
    end
end