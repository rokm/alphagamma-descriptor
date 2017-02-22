function [ correspondences, valid ] = evaluate_consistent_correspondences (self, sequence, ref_image_id, test_image_id, image_size, H21, keypoint_detector, ref_keypoints, test_keypoints)
    % [ correspondences, valid ] = EVALUATE_CONSISTENT_CORRESPONDENCES (self, sequence, ref_image_id, test_image_id, image_size, H21, keypoint_detector, ref_keypoints, test_keypoints)
    
    % Construct cache filename
    cache_file = '';
    if ~isempty(self.cache_dir)
        cache_path = fullfile(self.cache_dir, '_correspondences', keypoint_detector.identifier, sequence);
        cache_file = fullfile(cache_path, sprintf('%s_%s.correspondences.mat', ref_image_id, test_image_id));
    end
    
    % Evaluate consistent correspondences
    if ~isempty(cache_file) && exist(cache_file, 'file')
        % Load from cache
        tmp = load(cache_file);
        
        correspondences = tmp.correspondences;
        valid = tmp.valid;
    else
        % Consistent correspondences
        t = tic();
        
        % Pre-allocate outputs
        correspondences = cell(numel(test_keypoints), 1);
        valid = false(numel(test_keypoints), 1);
        
        % Gather coordinates of keypoints in reference image
        pt1 = vertcat(ref_keypoints.pt);
        
        % Find consistent correspondences for each keypoint in the
        % test image
        for j = 1:numel(test_keypoints)
            pt2 = test_keypoints(j).pt; % NOTE: we assume that both coordinates and transformation matrix are given in C-style coordinates
            
            % Project test keypoint back to reference image to
            % evaluate geometric consistency
            pt2p = H21 * [ pt2, 1 ]';
            pt2p = pt2p(1:2)' / pt2p(3);
            
            % Check if point projects inside the image
            if pt2p(1) < 0 || pt2p(1) >= image_size(2) || pt2p(2) < 0 || pt2p(2) >= image_size(1)
                valid(j) = false;
                continue;
            end
            
            % Compute distances to all points in reference image
            dist = sqrt(sum(bsxfun(@minus, pt1, pt2p).^2, 2));
            correspondences{j} = find(dist < self.backprojection_threshold);
            valid(j) = true;
        end
        
        time_correspondences = toc(t);
        
        % Save to cache
        if ~isempty(cache_file)
            vicos.utils.ensure_path_exists(cache_file);
            tmp = struct('correspondences', {correspondences}, 'valid', valid, 'time_correspondences', time_correspondences); %#ok<NASGU>
            save(cache_file, '-v7.3', '-struct', 'tmp');
        end
    end
end