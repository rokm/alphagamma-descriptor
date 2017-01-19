function [ keypoints, descriptors ] = extract_features_from_image (image_file, keypoint_detector, descriptor_extractor, cache_file)
    % [ keypoints, descriptors ] = EXTRACT_FEATURES_FROM_IMAGE (image_file, keypoint_detector, descriptor_extractor, cache_file)
    %
    % Computes keypoints and extracts descriptors from the image.
    % Optionally, if cache filename is provided, it attempts to
    % load cached results, or stores the results to the cache file
    % for later re-use.
    %
    % Input:
    %  - self:
    %  - image_file: full path to input image
    %  - keypoint_detector: instance of keypoint detector (i.e., a
    %    @vicos.keypoint_detector.Detector)
    %  - descriptor_extractor: instance of descriptor extractor
    %    (i.e., a @vicos.descriptor.Descriptor)
    %  - cache_file: optional cache filename; if provided,
    %
    % Output:
    %  - keypoints: 1xN array of OpenCV keypoint structures
    %  - descriptors: NxD array of corresponding descriptors
    
    % Load from cache, if available
    if ~isempty(cache_file) && exist(cache_file, 'file')
        tmp = load(cache_file);
        keypoints = tmp.keypoints;
        descriptors = tmp.descriptors;
        return;
    end
    
    % Load image
    I = imread(image_file);
    
    % Detect keypoints
    t = tic();
    keypoints = keypoint_detector.detect(I);
    time_keypoints = toc(t);
    
    % Extract descriptors
    t = tic();
    [ descriptors, keypoints ] = descriptor_extractor.compute(I, keypoints);
    time_descriptors = toc(t);
    
    % Save to cache
    if ~isempty(cache_file)
        vicos.utils.ensure_path_exists(cache_file);
        tmp = struct('keypoints', keypoints, 'time_keypoints', time_keypoints, 'descriptors', descriptors, 'time_descriptors', time_descriptors); %#ok<NASGU>
        save(cache_file, '-v7.3', '-struct', 'tmp');
    end
end