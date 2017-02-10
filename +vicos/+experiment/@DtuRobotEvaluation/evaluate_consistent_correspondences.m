function [ correspondences, valid ] = evaluate_consistent_correspondences (self, image_set, ref_image, test_image, light_number, keypoint_detector, ref_keypoints, test_keypoints)
    % [ correspondences, valid ] = EVALUATE_CONSISTENT_CORRESPONDENCES (self, image_set, ref_image, test_image, light_number, keypoint_detector, ref_keypoints, test_keypoints)
    %
    % Input:
    %  - self:
    
    cache_file = '';
    if ~isempty(self.cache_dir)
        cache_path = fullfile(self.cache_dir, '_correspondences', keypoint_detector.identifier, sprintf('SET%03d', image_set));
        cache_file = fullfile(cache_path, sprintf('SET%03d_Img%03d_%02d_Img%03d_%02d.keypoints.mat', image_set, ref_image, light_number, test_image, light_number));
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

        ref_camera = self.cameras(:,:,ref_image);
        test_camera = self.cameras(:,:,test_image);
        
        correspondences = cell(numel(ref_keypoints), 1);
        valid = false(numel(ref_keypoints), 1);

        % Find consistent correspondences for each keypoint in the
        % reference image
        test_pts2d = vertcat(test_keypoints.pt) + 1;
        test_scales = (0.5*vertcat(test_keypoints.size)).^2;

        for j = 1:numel(ref_keypoints)
            ref_pt2d = ref_keypoints(j).pt + 1;
            ref_scale = (0.5*ref_keypoints(j).size)^2;

            [ correspondences{j}, valid(j) ] = self.get_consistent_correspondences(quad3d, ref_camera, test_camera, ref_pt2d, ref_scale, test_pts2d, test_scales);
        end
        
        time_correspondences = toc(t);
        
         % Save to cache
        if ~isempty(cache_file)
            vicos.utils.ensure_path_exists(cache_file);
            tmp = struct('correspondences', correspondences, 'valid', valid, 'time_correspondences', time_correspondences); %#ok<NASGU>
            save(cache_file, '-v7.3', '-struct', 'tmp');
        end
    end
end