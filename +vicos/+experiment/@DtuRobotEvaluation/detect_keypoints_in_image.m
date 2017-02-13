function [ keypoints, I ] = detect_keypoints_in_image (self, image_set, image_number, light_number, I, keypoint_detector)
    % [ keypoints, I ] = DETECT_KEYPOINTS_IN_IMAGE (self, image_set, image_number, light_number, I, keypoint_detector)
    % 
    % Detects keypoints in the specified image, with support for optional
    % image loading and caching of results.
    %
    % Input:
    %  - self:
    %  - image_set: image set number
    %  - image_number: image number
    %  - light_number: light number
    %  - I: optional image (if empty, image will be loaded on demand by
    %    constructing the filename from image_set, image_number and 
    %    light_number)
    %  - keypoint_detector: vicos.keypoint_detector.KeypointDetector
    %    instance
    %
    % Output:
    %  - keypoints: 1xN array of OpenCV keypoint structures
    %  - I: image data (empty if image loading was not required)
    
    % Construct cache filename
    cache_file = '';
    if ~isempty(self.cache_dir)
        cache_path = fullfile(self.cache_dir, '_keypoints', keypoint_detector.identifier, sprintf('SET%03d', image_set));
        cache_file = fullfile(cache_path, sprintf('SET%03d_Img%03d_%02d.keypoints.mat', image_set, image_number, light_number));
    end
    
    % Detect keypoints
    if ~isempty(cache_file) && exist(cache_file, 'file')
        % Load from cache
        tmp = load(cache_file);
        keypoints = tmp.keypoints;
        image_size = tmp.image_size;
    else
        % Load image if necessary
        if isempty(I)
            image_file = self.construct_image_filename(image_set, image_number, light_number);
            I = imread(image_file);
        end
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
    
    % Sanity check; validate image size
    if self.half_size_images
        assert(image_size(1) == 600 && image_size(2) == 800, 'Half-sized images must be 800x600!')
    else
        assert(image_size(1) == 1200 && image_size(2) == 1600, 'Full-sized images must be 1600x1200!')
    end
    
    % Filter keypoints at image border
    image_height = image_size(1);
    image_width = image_size(2);
    
    pts = vertcat(keypoints.pt) + 1; % C -> Matlab coordinates
    
    valid_mask = pts(:,1) >= (1+self.filter_border) & pts(:,1) <= (image_width-self.filter_border) & pts(:,2) >= (1+self.filter_border) & pts(:,2) <= (image_height-self.filter_border);
    keypoints(~valid_mask) = [];
end