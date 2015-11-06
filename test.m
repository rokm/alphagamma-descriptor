clear;
close all;

keypoint_distance_threshold = 2.5;
filter_border = 25;
num_points = 1000;
num_repetitions = 10;
visualize_sets = false;

dataset = AffineDataset();

%[ I1, I2, H12 ] = dataset.get_rotated_image('graffiti', 1, -30);
[ I1, I2, H12 ] = dataset.get_image_pair('graffiti', 1, 2);

keypoint_detector = vicos.keypoint_detector.SURF();
%keypoint_detector = cv.FeatureDetector('SIFT');

%descriptor_extractor = cv.DescriptorExtractor('SURF', 'HessianThreshold', 400, 'NOctaves', 3, 'NOctaveLayers', 4);
%descriptor_extractor = cv.DescriptorExtractor('SURF');
descriptor_extractor = vicos.descriptor.SURF();
%descriptor_extractor = cv.DescriptorExtractor('BriefDescriptorExtractor');

%% Gather a set of corresponding keypoints
correspondence_sets = detect_corresponding_keypoints(I1, I2, H12, keypoint_detector, 'distance_threshold', keypoint_distance_threshold, 'num_points', num_points, 'num_sets', num_repetitions, 'filter_border', filter_border, 'visualize', visualize_sets);

recognition_rate = zeros(1, num_repetitions);
for r = 1:num_repetitions,
    % Get the set for r-th repetition
    keypoint_distances = correspondence_sets(r).distances;
    keypoints1 = correspondence_sets(r).keypoints1;
    keypoints2 = correspondence_sets(r).keypoints2;
    
    % Geometry-based correspondences; note that we allow multiple
    % correspondences per point; this gracefully handles the cases with
    % multiple keypoints detected in close vicinity or even at the same
    % location, which would make it difficult to justify one particular hard
    % assignment over the other
    correspondences = keypoint_distances < keypoint_distance_threshold;

    %% Evaluate descriptor
    recognition_rate(r) = evaluate_descriptor_extractor(I1, I2, keypoints1, keypoints2, correspondences, descriptor_extractor);
end

fprintf('Recognition rate: %.2f +/- %.2f %%\n', 100*mean(recognition_rate), 100*std(recognition_rate));