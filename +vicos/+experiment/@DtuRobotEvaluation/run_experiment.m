function results = run_experiment (self, keypoint_detector, descriptor_extractor, image_set, varargin)
    % Input:
    %  - self:
    %  - keypoint_detector: function handle that creates keypoint
    %    detector instance, or a keypoint detector instance
    %  - descriptor_extractor: function handle that creates
    %    descriptor extractor instance, or a descriptor extractor
    %    instance
    %  - image_set: image set to perform experiment on.
    %  - varargin: optional key/value pairs
    %    - cache_dir: cache directory; default: use global cache dir
    %      setting
    %    - reference_image: reference/key image to which all others
    %     are compared (default: 25)
    %    - test_images: list of test images; default: all (1~119)
    %    - light_number: number of light preset to use; default: 8
        
    % Parse arguments
    parser = inputParser();
    parser.addParameter('reference_image', 25, @isnumeric);
    parser.addParameter('test_images', [], @isnumeric);
    parser.addParameter('light_number', 8, @isnumeric);
    parser.addParameter('cache_dir', self.cache_dir, @ischar);
    parser.parse(varargin{:});
    
    ref_image = parser.Results.reference_image;
    test_images = parser.Results.test_images;
    light_number = parser.Results.light_number;
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
    if isempty(test_images)
        % All but reference
        test_images = setdiff(1:size(self.cameras, 3), ref_image);
    end
    
    %% Prepare
    % Pre-compute the quad tree of projected structured-light
    % points, which serves as ground-truth for evaluation
    quad3d = self.generate_structured_light_grid(image_set, ref_image);
        
    %% Process reference image   
    fprintf('Processing reference image (seq #%03d, img #%03d, light #%02d)\n', image_set, ref_image, light_number);
    
    % Detect keypoints
    Ir = [];
    [ ref_keypoints_raw, Ir ] = self.detect_keypoints_in_image(image_set, ref_image, light_number, Ir, keypoint_detector);
    
    % Extract descriptors
    [ ref_descriptors, ref_keypoints ] = self.extract_descriptors_from_keypoints(image_set, ref_image, light_number, Ir, keypoint_detector, ref_keypoints_raw, descriptor_extractor);
        
    %% Pre-allocate results structure
%     results = repmat(struct('sequence', [], ...
%                             'lighting', [], ...
%                             'reference_image', [], ...
%                             'test_image', [], ...
%                             'putative_matches', [], ...
%                             'correct_matches', [], ...
%                             'putative_matches_unique', [], ...
%                             'correct_matches_unique', [], ...
%                             'consistent_correspondences', []), 1, numel(test_images));
    
    %% Process all test images
    for i = 1:numel(test_images)
        test_image = test_images(i);
        
        fprintf('Processing test image #%d/%d (seq #%03d, img #%03d, light #%02d)\n', i, numel(test_images), image_set, test_image, light_number);
        
        %% Process test image
        % Detect keypoints
        It = [];
        [ test_keypoints_raw, It ] = self.detect_keypoints_in_image(image_set, test_image, light_number, It, keypoint_detector);

        % Extract descriptors
        [ test_descriptors, test_keypoints ] = self.extract_descriptors_from_keypoints(image_set, test_image, light_number, It, keypoint_detector, test_keypoints_raw, descriptor_extractor);
        
        %% Evaluate consistent correspondences
        % Note: the results are cached on per-keypoint detector level (i.e,
        % the value is cached across all descriptors extracted from the
        % given keypoint type)
        fprintf('Evaluating consistent references for pair #%d|#%d\n', test_image, ref_image);
        [ consistent_correspondences, valid_correspondences ] = self.evaluate_consistent_correspondences(image_set, ref_image, test_image, light_number, quad3d, keypoint_detector, ref_keypoints_raw, test_keypoints_raw);
        
        % FIXME: post-process and compute histogram!
        
        %% Evaluate putative and correct matches
        [ match_idx, match_dist, consistent_matches, putative_matches ] = self.evaluate_matches(image_set, ref_image, test_image, light_number, quad3d, keypoint_detector, descriptor_extractor, ref_keypoints, ref_descriptors, test_keypoints, test_descriptors);
        [ roc, area ] = self.compute_roc_curve(match_dist(:,1)./match_dist(:,2), consistent_matches);

%         %% Compute final results
%         results(i).sequence = image_set;
%         results(i).lighting = light_number;
%         results(i).reference_image = ref_image;
%         results(i).test_image = test_image;
% 
%         results(i).num_putative_matches = sum(putative_matches);
%         results(i).num_correct_matches = sum((consistent_matches == 1) & putative_matches); % Correct matches: putative matches that are geometrically consistent
% 
%                 
%         % Construct the array of coordinate pairings; used to filter
%         % out duplicates
%         pairings = [ match.coord, match.coordKey(match.matchIdx(:,1),:) ];
%         
%         results(i).putative_matches_unique = size(unique(pairings(putative_matches,:), 'rows'), 1);
%         results(i).correct_matches_unique = size(unique(pairings(correct_matches,:), 'rows'), 1);
%         
%         % Number of consistent correspondences
%         results(i).consistent_correspondences = sum(consistent_correspondences.histogram(2:end));
    end
end
