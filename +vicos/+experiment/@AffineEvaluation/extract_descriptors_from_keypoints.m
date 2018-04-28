function [ descriptors, keypoints ] = extract_descriptors_from_keypoints (self, sequence, image_id, I, keypoint_detector, keypoints, descriptor_extractor)
    % [ descriptors, keypoints ] = EXTRACT_DESCRIPTORS_FROM_KEYPOINTS (self, sequence, image_id, I, keypoint_detector, keypoints, descriptor_extractor)
    %
    % Extracts descriptors from keypoints.
    %
    % Input:
    %  - self:
    %  - sequence:
    %  - image_id:
    %  - I:
    %  - keypoint_detector:
    %  - keypoints:
    %  - descriptor_extractor:
    %
    % Output:
    %  - descriptors:
    %  - keypoints:
    
    % Construct cache filename
    cache_file = '';
    if self.cache_descriptors && ~isempty(self.cache_dir)
        cache_path = fullfile(self.cache_dir, '_descriptors', sprintf('%s+%s', keypoint_detector.identifier, descriptor_extractor.identifier), sequence);
        cache_file = fullfile(cache_path, sprintf('%s.descriptors.mat', image_id));
    end
    
    % Extract descriptors
    if ~isempty(cache_file) && exist(cache_file, 'file')
        % Load from cache
        tmp = load(cache_file);
        keypoints = tmp.keypoints;
        descriptors = tmp.descriptors;
    else
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
end
