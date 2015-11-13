function results = batch_experiment_image_pairs (keypoint_detector, descriptor_extractors, varargin)
    % Input parameters
    parser = inputParser();
    parser.addParameter('sequence', 'graffiti', @ischar);
    parser.addParameter('pairs', [ 2, 3, 4, 5, 6 ], @isnumeric);
    parser.addParameter('num_points', 1000, @isscalar);
    parser.addParameter('num_repetitions', 5, @isscalar);
    parser.addParameter('visualize_sets', false, @islogical);
    parser.addParameter('keypoint_distance_threshold', 2.5, @isnumeric);
    parser.addParameter('filter_border', 50, @isnumeric);
    parser.parse(varargin{:});
    
    sequence = parser.Results.sequence;
    pairs = parser.Results.pairs;
    
    num_points = parser.Results.num_points;
    num_repetitions = parser.Results.num_repetitions;

    keypoint_distance_threshold = parser.Results.keypoint_distance_threshold;
    filter_border = parser.Results.filter_border;
    visualize_sets = parser.Results.visualize_sets;

    %% Dataset
    dataset = AffineDataset();

    %% Process all image pairs
    recognition_rates = nan(num_repetitions, size(descriptor_extractors, 1), numel(pairs));
    for i = 1:numel(pairs),
        p = pairs(i);

        fprintf('\n--- Image pair: %d/%d ---\n', 1, p);

        % Generate image pair
        [ I1, I2, H12 ] = dataset.get_image_pair(sequence, 1, p);

        % Experiment
        recognition_rates(:,:,i) = evaluate_descriptor_extractors_on_image_pair(I1, I2, H12, keypoint_detector, descriptor_extractors, keypoint_distance_threshold, num_points, num_repetitions, filter_border, visualize_sets);
    end
        
    %% Store results
    results.recognition_rates = recognition_rates;
    results.descriptor_names = descriptor_extractors(:,1);
    results.pairs = pairs;
    results.sequence = sequence;
end


function recognition_rates = evaluate_descriptor_extractors_on_image_pair (I1, I2, H12, keypoint_detector, descriptor_extractors, keypoint_distance_threshold, num_points, num_repetitions, filter_border, visualize_sets)
    % recognition_rates = EVALUATE_DESCRIPTOR_EXTRACTORS_ON_IMAGE_PAIR
    % (I1, I2
    % 
    % 
    %% Gather a set of corresponding keypoints
    fprintf('Obtaining set(s) of correspondences from the image pair...\n');
    %t = tic();
    correspondence_sets = detect_corresponding_keypoints(I1, I2, H12, keypoint_detector, 'distance_threshold', keypoint_distance_threshold, 'num_points', num_points, 'num_sets', num_repetitions, 'filter_border', filter_border, 'visualize', visualize_sets);
    %fprintf('Done (%f seconds)!\n', toc(t));

    fprintf('Evaluating descriptors...\n');
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
end