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
    %    - cache_dir: cache directory; default: use global cache dir
    %      setting
        
    % Parse arguments
    parser = inputParser();
    parser.addParameter('cache_dir', self.cache_dir, @ischar);
    parser.parse(varargin{:});
    
    cache_root = parser.Results.cache_dir;
    
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
    
    % Default test images
    %if isempty(test_images)
        % All but reference
        test_images = 2:6;
    %end
    
    %% Process all pairs
    for i = 1:numel(test_images)
        ref_image = 1;
        test_image = test_images(i);
        
         fprintf('Processing test image #%d/%d (seq %s, ref %d, test %d)\n', i, numel(test_images), sequence, ref_image, test_image);

         [ I1, I2, H12 ] = self.get_image_pair(sequence, ref_image, test_image);
         H21 = inv(H12); % Invert the projection matrix (image 1 is our reference image, so we need projection into it, not from it)
         
         %% Process reference image
         % Detect keypoints
         ref_keypoints_raw = self.detect_keypoints_in_image(I1, keypoint_detector);
         
         [ ref_descriptors, ref_keypoints ] = self.extract_descriptors_from_keypoints(I1, keypoint_detector, ref_keypoints_raw, descriptor_extractor);
         
         %% Process test image
         % Detect keypoints
         test_keypoints_raw = self.detect_keypoints_in_image(I2, keypoint_detector);
         
         [ test_descriptors, test_keypoints ] = self.extract_descriptors_from_keypoints(I2, keypoint_detector, test_keypoints_raw, descriptor_extractor);
         
         %% Evaluate matches
         [ match_idx, match_dist, consistent_matches, putative_matches ] = self.evaluate_matches(H21, size(I1), keypoint_detector, descriptor_extractor, ref_keypoints, ref_descriptors, test_keypoints, test_descriptors);
    end
end