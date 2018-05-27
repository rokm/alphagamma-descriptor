function [ match_idx, match_dist, correct_matches, putative_matches, time_per_distance ] = evaluate_matches (self, image_set, ref_image, test_image, light_number, quad3d, keypoint_detector, descriptor_extractor, ref_keypoints, ref_descriptors, test_keypoints, test_descriptors)
    % [ match_idx, match_dist, correct_matches, putative_matches, time_per_distance ] = EVALUATE_MATCHES (self, image_set, ref_image, test_image, light_number, quad3d, keypoint_detector, descriptor_extractor, ref_keypoints, ref_descriptors, test_keypoints, test_descriptors)
    %
    % Evaluates the keypoint/descriptor matches in terms of putative and
    % correct matches.
    %
    % Input:
    %
    % Output:
    %
    
    % Construct cache filename
    cache_file = '';
    if ~isempty(self.cache_dir)
        cache_path = fullfile(self.cache_dir, '_matches', sprintf('%s+%s', keypoint_detector.identifier, descriptor_extractor.identifier), sprintf('SET%03d', image_set));
        cache_file = fullfile(cache_path, sprintf('SET%03d_Img%03d_%02d_Img%03d_%02d.matches.mat', image_set, ref_image, light_number, test_image, light_number));
    end
    
    % Process
    if ~isempty(cache_file) && exist(cache_file, 'file')
        % Load from cache
        tmp = load(cache_file);
        
        match_idx = tmp.match_idx;
        match_dist = tmp.match_dist;
        correct_matches = tmp.correct_matches;
        putative_matches = tmp.putative_matches;
        time_per_distance = tmp.time_per_distance;
    else
        % Find closest matches
        batch_size = 1000; % Limit memory consumption by splitting test descriptors into batches
        [ match_idx, match_dist, time_per_distance ] = find_closest_matches (descriptor_extractor, ref_descriptors, test_descriptors, batch_size);
        
        % Camera matrices
        ref_camera = self.cameras(:,:,ref_image);
        test_camera = self.cameras(:,:,test_image);
        
        % Upscale keypoints to full-size image
        if self.half_size_images
            ref_keypoints = self.upscale_keypoints_to_full_image_size(ref_keypoints);
            test_keypoints = self.upscale_keypoints_to_full_image_size(test_keypoints);
        end
        
        % Determine geometric consistency of matches
        correct_matches = nan(numel(test_keypoints), 1);
        for j = 1:numel(test_keypoints)
            % Get the coordinates of the matched pair
            pt2 = test_keypoints(j).pt;
            pt1 = ref_keypoints(match_idx(j,1)).pt;
            
            % Convert C -> Matlab coordinates
            pt1 = pt1 + 1;
            pt2 = pt2 + 1;
            
            % Evaluate
            correct_matches(j) = self.is_match_consistent(quad3d, ref_camera, test_camera, pt1', pt2');
        end
        
        putative_matches = (match_dist(:,1) ./ match_dist(:,2)) < self.putative_match_ratio;
        
        % Save to cache
        if ~isempty(cache_file)
            vicos.utils.ensure_path_exists(cache_file);
            tmp = struct('match_idx', match_idx, 'match_dist', match_dist, 'correct_matches', correct_matches, 'putative_matches', putative_matches, 'time_per_distance', time_per_distance); %#ok<NASGU>
            save(cache_file, '-v7.3', '-struct', 'tmp');
        end 
    end
end

function [ match_idx, match_dist, time_per_distance ] = find_closest_matches (descriptor_extractor, ref_descriptors, test_descriptors, batch_size)
    % [ match_idx, match_dist, time_per_distance ] = FIND_CLOSEST_MATCHES (descriptor_extractor, ref_descriptors, test_descriptors, batch_size)
    %
    % For each test_descriptor, finds the 1st and 2nd closest match among
    % the ref_descriptors, and returns their indices and distances.
    %
    % Input:
    %  - descriptor_extractor: descriptor extractor instance (needed for
    %    distance function)
    %  - ref_descriptors: reference descriptors (NxD matrix)
    %  - test_descriptors: test descriptors (MxD matrix)
    %  - batch_size: optional batch size to limit memory consmuption
    %    (default: inf)
    %
    % Output:
    %  - match_idx: Mx2 array of match indices (1st and 2nd match) for each
    %    test descriptor
    %  - match_dist: Mx2 array of match distances (1st and 2nd match) for 
    %    each test descriptor
    %  - time_per_distance: amortized computation time per distance between
    %    two descriptors

    if ~exist('batch_size', 'var') || isempty(batch_size)
        batch_size = inf;
    end
    
     % We do not know the type of match distance (because it depends on 
     % descriptor size), so we will allocate 
    match_idx = [];
    match_dist = [];
    
    num_test_descriptors = size(test_descriptors, 1);
    num_processed = 0;
    
    if ~isfinite(batch_size)
        batch_size = num_test_descriptors;
    end
    
    time_per_distance = [];

    while num_processed < num_test_descriptors
        % Clamp batch size
        batch_size = min(batch_size, num_test_descriptors - num_processed);
        
        % Determine indices
        pos1 = num_processed + 1;
        pos2 = pos1 + batch_size - 1;
        
        % Compute descriptor distance matrix
        t = tic();
        M = descriptor_extractor.compute_pairwise_distances(ref_descriptors, test_descriptors(pos1:pos2, :));
        time_per_distance(end+1) = toc(t) / numel(M); %#ok<AGROW>
        
        % For each test keypoint (row in M), find the closest match
        [ min_dist1, min_idx1 ] = min(M, [], 2); % For each test keypoint, find the closest match

        % Find the next closest match (by masking the closest one)
        cidx = sub2ind(size(M), (1:numel(min_idx1))', min_idx1);
        M(cidx) = inf;
        [ min_dist2, min_idx2 ] = min(M, [], 2);
        
        % Store indices and distances
        if isempty(match_dist)
            match_dist = zeros(num_test_descriptors, 2, 'like', min_dist1);
            match_idx = zeros(num_test_descriptors, 2, 'like', min_idx1);
        end
        
        match_dist(pos1:pos2,:) = [ min_dist1, min_dist2 ];
        match_idx(pos1:pos2,:) = [ min_idx1, min_idx2 ];
        
        % Update the count
        num_processed = num_processed + batch_size;
    end
    
    time_per_distance = mean(time_per_distance); % Average across all batches
end
