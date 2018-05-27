function [ descriptors, keypoints, time_per_descriptor ] = extract_descriptors_from_keypoints (self, image_set, image_number, light_number, I, keypoint_detector, keypoints, descriptor_extractor)
    % [ descriptors, keypoints, time_per_descriptor ] = EXTRACT_DESCRIPTORS_FROM_KEYPOINTS (self, image_set, image_number, light_number, I, keypoint_detector, keypoints, descriptor_extractor)
    %
    % Extracts descriptors from detected keypoints.
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
    %    (used to generate cache file names)
    %  - keypoints: 1xN array of OpenCV keypoint structures
    %  - descriptor_extractor: vicos.descriptor.Descriptor instance
    %
    % Output:
    %  - descriptors: MxD matrix of descriptors, where M <= N, and D is
    %    descriptor size
    %  - keypoints: 1xM array of OpenCV keypoint structures. The class_id
    %    field has been modified to provide indices to the original input
    %    array of keypoints, to allow tracking of keypoints that were
    %    discarded by descriptor extractor.
    %  - time_per_descriptor: amortized computation time per descriptor
    
    % Construct cache filename
    cache_file = '';
    if self.cache_descriptors && ~isempty(self.cache_dir)
        cache_path = fullfile(self.cache_dir, '_descriptors', sprintf('%s+%s', keypoint_detector.identifier, descriptor_extractor.identifier), sprintf('SET%03d', image_set));
        cache_file = fullfile(cache_path, sprintf('SET%03d_Img%03d_%02d.descriptors.mat', image_set, image_number, light_number));
    end
    
    % Extract descriptors
    if ~isempty(cache_file) && exist(cache_file, 'file')
        % Load from cache
        tmp = load(cache_file);
        keypoints = tmp.keypoints;
        descriptors = tmp.descriptors;
        time_descriptors = tmp.time_descriptors;
    else
        % Load image, if necessary
        if isempty(I)
            image_file = self.construct_image_filename(image_set, image_number, light_number);
            I = imread(image_file);
            if self.force_grayscale
                I = rgb2gray(I);
            end
        end
        
        % Augment keypoints with sequential class IDs, so we can track
        % which points were dropped by descriptor extractor
        assert(all([ keypoints.class_id ] == -1), 'Keypoints do not have their class_id field set to -1! This may mean that the keypoint detector/descriptor extractor is using this field for its own purposes, which is not supported by this evaluation framework!');
    
        ids = num2cell(1:numel(keypoints));
        [ keypoints.class_id ] = deal(ids{:});
        
        % Extract descriptors
        t = tic();
        [ descriptors, keypoints ] = descriptor_extractor.compute(I, keypoints);
        time_descriptors = toc(t);
        
        % Save to cache
        if ~isempty(cache_file)
            vicos.utils.ensure_path_exists(cache_file);
            tmp = struct('keypoints', keypoints, 'descriptors', descriptors, 'time_descriptors', time_descriptors); %#ok<NASGU>
            save(cache_file, '-v7.3', '-struct', 'tmp');
        end
    end
    
    % Compute amortized computation time per descriptor
    time_per_descriptor = time_descriptors / size(descriptors, 1);
end
