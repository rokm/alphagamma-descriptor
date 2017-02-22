function keypoints = detect_keypoints_in_image (self, sequence, image_id, I, keypoint_detector)
    % keypoints = DETECT_KEYPOINTS_IN_IMAGE (self, sequence, image_id, I, keypoint_detector)
    %
    % Detects keypoints in the image.
    %
    % Input:
    %  - self:
    %  - sequence:
    %  - image_id:
    %  - I:
    %  - keypoint_detector
    %
    % Output:
    %  - keypoints
    
    % Construct cache filename
    cache_file = '';
    if ~isempty(self.cache_dir)
        cache_path = fullfile(self.cache_dir, '_keypoints', keypoint_detector.identifier, sequence);
        cache_file = fullfile(cache_path, sprintf('%s.keypoints.mat', image_id));
    end
    
    % Detect keypoints
    if ~isempty(cache_file) && exist(cache_file, 'file')
        % Load from cache
        tmp = load(cache_file);
        keypoints = tmp.keypoints;
        image_size = tmp.image_size;
        
        % Sanity check
        assert(isequal(image_size, size(I)), 'Inconsistent image size!');
    else
        image_size = size(I);
        
        % Detect keypoints
        t = tic();
        keypoints = keypoint_detector.detect(I);
        time_keypoints = toc(t);
        
        % Save to cache
        if ~isempty(cache_file)
            vicos.utils.ensure_path_exists(cache_file);
            tmp = struct('keypoints', keypoints, 'time_keypoints', time_keypoints, 'image_size', image_size); %#ok<NASGU>
            save(cache_file, '-v7.3', '-struct', 'tmp');
        end
    end
    
    % Filter keypoints at image border
    image_height = image_size(1);
    image_width = image_size(2);
    
    pts = vertcat(keypoints.pt) + 1; % C -> Matlab coordinates
    
    valid_mask = pts(:,1) >= (1+self.filter_border) & pts(:,1) <= (image_width-self.filter_border) & pts(:,2) >= (1+self.filter_border) & pts(:,2) <= (image_height-self.filter_border);
    keypoints(~valid_mask) = [];
end