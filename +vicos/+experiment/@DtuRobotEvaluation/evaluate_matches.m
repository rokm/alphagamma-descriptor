function [ match_idx, match_dist, correct_matches, putative_matches ] = evaluate_matches (self, image_set, ref_image, test_image, light_number, quad3d, keypoint_detector, descriptor_extractor, ref_keypoints, ref_descriptors, test_keypoints, test_descriptors)
    % [ match_idx, match_dist, correct_matches, putative_matches ] = EVALUATE_MATCHES (self, image_set, ref_image, test_image, light_number, quad3d, keypoint_detector, descriptor_extractor, ref_keypoints, ref_descriptors, test_keypoints, test_descriptors)
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
    else
        % Compute descriptor distance matrix
        M = descriptor_extractor.compute_pairwise_distances(ref_descriptors, test_descriptors);
        
        % For each test keypoint (row in M), find the closest match
        [ min_dist1, min_idx1 ] = min(M, [], 2); % For each test keypoint, find the closest match
        
        % Find the next closest match (by masking the closest one)
        cidx = sub2ind(size(M), [ 1:numel(min_idx1) ]', min_idx1);
        M(cidx) = inf;
        [ min_dist2, min_idx2 ] = min(M, [], 2);
        
        % Store indices and distances
        match_idx = [ min_idx1, min_idx2 ];
        match_dist = [ min_dist1, min_dist2 ];
        
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
        
        putative_matches = (min_dist1 ./ min_dist2) < self.putative_match_ratio;
        
        % Save to cache
        if ~isempty(cache_file)
            vicos.utils.ensure_path_exists(cache_file);
            tmp = struct('match_idx', match_idx, 'match_dist', match_dist, 'correct_matches', correct_matches, 'putative_matches', putative_matches); %#ok<NASGU>
            save(cache_file, '-v7.3', '-struct', 'tmp');
        end 
    end
end
