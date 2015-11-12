clear;
close all;

keypoint_distance_threshold = 2.5;
filter_border = 50;
num_points = 1000;
num_repetitions = 1;
visualize_sets = false;

dataset = AffineDataset();

%[ I1, I2, H12 ] = dataset.get_rotated_image('graffiti', 1, -30);
[ I1, I2, H12 ] = dataset.get_image_pair('graffiti', 1, 2);

keypoint_detector = vicos.keypoint_detector.SURF('HessianThreshold', 400, 'NOctaves', 3, 'NOctaveLayers', 4);
%keypoint_detector = cv.FeatureDetector('SIFT');

descriptor_extractor = cell(0, 2);

descriptor_extractor(end+1, :) = { 'SURF',  vicos.descriptor.SURF() };
descriptor_extractor(end+1, :) = { 'O-BRIEF-64', vicos.descriptor.BRIEF('Bytes', 64, 'UseOrientation', true) };
descriptor_extractor(end+1, :) = { 'O-LATCH-64', vicos.descriptor.LATCH('Bytes', 64, 'RotationInvariance', true) };
descriptor_extractor(end+1,:) = { 'U-AlphaGamma-C23 E', vicos.descriptor.AlphaGamma('orientation', false, 'extended', true, 'sampling', 'gaussian', 'use_scale', false, 'num_rays', 23) };
descriptor_extractor(end+1,:) = { 'OD: U-AlphaGamma-C23 E', vicos.descriptor.AlphaGamma('orientation', false, 'extended', true, 'sampling', 'gaussian', 'use_scale', false, 'num_rays', 23, 'slow_distance', true) };
descriptor_extractor(end+1,:) = { 'Orig: U-AlphaGamma-C23 E', vicos.descriptor.AlphaGammaOld('orientation', false, 'extended', true, 'sampling', 'gaussian', 'use_scale', false, 'num_rays', 23) };
descriptor_extractor(end+1,:) = { 'O-AlphaGamma-C23 E', vicos.descriptor.AlphaGamma('orientation', true, 'extended', true, 'sampling', 'gaussian', 'use_scale', false, 'num_rays', 23) };
descriptor_extractor(end+1,:) = { 'OD: O-AlphaGamma-C23 E', vicos.descriptor.AlphaGamma('orientation', true, 'extended', true, 'sampling', 'gaussian', 'use_scale', false, 'num_rays', 23, 'slow_distance', true) };
descriptor_extractor(end+1,:) = { 'Orig: O-AlphaGamma-C23 E', vicos.descriptor.AlphaGammaOld('orientation', true, 'extended', true, 'sampling', 'gaussian', 'use_scale', false, 'num_rays', 23) };

%% Gather a set of corresponding keypoints
fprintf('Obtaining set(s) of correspondences from the image pair...\n');
t = tic();
correspondence_sets = detect_corresponding_keypoints(I1, I2, H12, keypoint_detector, 'distance_threshold', keypoint_distance_threshold, 'num_points', num_points, 'num_sets', num_repetitions, 'filter_border', filter_border, 'visualize', visualize_sets);
fprintf('Done (%f seconds)!\n', toc(t));

fprintf('Evaluating descriptors...\n');
num_descriptors = size(descriptor_extractor, 1);
recognition_rate = zeros(num_repetitions, num_descriptors);
for r = 1:num_repetitions,
    fprintf(' > repetition #%d/%d\n', r, num_repetitions);
    
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
    for d = 1:num_descriptors,
        fprintf('  >> %s\n', descriptor_extractor{d, 1});
        recognition_rate(r,d) = evaluate_descriptor_extractor(I1, I2, keypoints1, keypoints2, correspondences, descriptor_extractor{d, 2});
    end
end

%%
for d = 1:num_descriptors,
    fprintf('%s: %.2f +/- %.2f %%\n', descriptor_extractor{d,1}, 100*mean(recognition_rate(:,d)), 100*std(recognition_rate(:,d)));
end