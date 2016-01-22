function [ recognition_rates, num_detected_keypoints1, num_detected_keypoints2, num_established_correspondences ] = affine_evaluate_descriptor_extractors_on_image_pair (I1, I2, H12, keypoint_detector, descriptor_extractors, project_keypoints, keypoint_distance_threshold, num_points, num_repetitions, filter_border, visualize_sets)
    % recognition_rates = EVALUATE_DESCRIPTOR_EXTRACTORS_ON_IMAGE_PAIR (I1, I2, H12, keypoint_detector, descriptor_extractors, project_keypoints, keypoint_distance_threshold, num_points, num_repetitions, filter_border, visualize_sets)
    %
    % Evaluates given set of descriptor extractors on a pair of input
    % images and keypoints, detected using the given keypoint detector.
    %
    % Input:
    %  - I1: first image
    %  - I2: second image
    %  - H12: homography describing transformation from I1 to I2
    %  - keypoint_detector: keypoint detector
    %    (vicos.keypoint_detector.KeypointDetector instance)
    %  - descriptor_extractors: Nx2 cell array, where first column contains
    %    description strings, and second one contains objects subclassing 
    %    vicos.descriptor.Descriptor
    %  - project_keypoints: if set to false (default), keypoints are 
    %    detected in both first and second image, and then matched via 
    %    homography and distance constraints. If set to true, the keypoints 
    %    are detected only in the first image, and then directly projected 
    %    to the second image via homography. Useful for mitigating effects 
    %    of poor keypoint localization on descriptor's performance with
    %    certain types of transformations (pure rotation, pure scaling).
    %  - keypoint_distance_threshold: distance threshold used when
    %    establishing ground-truth geometry-based correspondences
    %  - num_points: number of point correspondences to randomly sample
    %    if more correspondences are obtained
    %  - num_repetitions: number of repetitions
    %  - filter_border: width of image border within which the points
    %    are filtered out to prevent access accross the image borders
    %  - visualize_sets: visualize the correspondence sets (each drawn
    %    set in a separate figure) (default: false)
    %
    % Output:
    %  - recognition_rates: RxNxP matrix of resulting recognition rates,
    %    with R being number of repetitions, N being number of descriptor
    %    extractors, and P being number of pairs
    %  - num_detected_keypoints1: number of keypoints detected in I1
    %  - num_detected_keypoints2: number of keypoints detected in I2
    %  - num_established_correspondences: number of geometric
    %    correspondences established between the two sets of keypoints
    %  - num_chosen_correspondences: number of selected correspondences
    %    (copy of the num_points parameter)
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    %% Gather a set of corresponding keypoints
    fprintf('Obtaining set(s) of correspondences from the image pair...\n');
    %t = tic();
    [ correspondence_sets, num_detected_keypoints1, num_detected_keypoints2, num_established_correspondences ] = affine_detect_corresponding_keypoints(I1, I2, H12, keypoint_detector, 'project_keypoints', project_keypoints, 'distance_threshold', keypoint_distance_threshold, 'num_points', num_points, 'num_sets', num_repetitions, 'filter_border', filter_border, 'visualize', visualize_sets);
    %fprintf('Done (%f seconds)!\n', toc(t));

    original_num_repetitions = num_repetitions;
    num_repetitions = numel(correspondence_sets); % Update number of repetitions
    
    fprintf('Evaluating descriptor extractors...\n');
    num_descriptors = size(descriptor_extractors, 1);
    recognition_rates = zeros(num_repetitions, num_descriptors);
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

        %% Evaluate descriptors
        for d = 1:num_descriptors,
            recognition_rates(r,d) = evaluate_descriptor_extractor(I1, I2, keypoints1, keypoints2, correspondences, descriptor_extractors{d, 2});
        end
    end
    
    % Duplicate results if necessary
    if original_num_repetitions ~= num_repetitions,
        recognition_rates = repmat(recognition_rates, original_num_repetitions, 1);
    end
end