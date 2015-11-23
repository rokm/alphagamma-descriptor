function results = affine_batch_experiment_image_pairs (keypoint_detector, descriptor_extractors, varargin)
    % results = AFFINE_BATCH_EXPERIMENT_IMAGE_PAIRS (keypoint_detector, descriptor_extractors, varargin)
    %
    % Batch experiments on image pair sequences from Oxford Affine dataset.
    %
    % Input:
    %  - keypoint_detector: keypoint detector
    %    (vicos.keypoint_detector.KeypointDetector instance)
    %  - descriptor_extractors: Nx2 cell array, where first column contains
    %    description strings, and second one contains objects subclassing 
    %     vicos.descriptor.Descriptor
    %  - varargin: optional key/value pairs:
    %     - sequence: sequence name (default: graffiti)
    %     - pairs: array of image numbers to compare against the first
    %       image in the sequence (default: [ 2, 3, 4, 5, 6 ])
    %     - num_points: number of point correspondences to randomly sample
    %       if more correspondences are obtained (default: 1000)
    %     - num_repetitions: number of repetitions (default: 5)
    %     - visualize_sets: visualize the correspondence sets (each drawn
    %       set in a separate figure) (default: false)
    %     - keypoint_distance_threshold: distance threshold used when
    %       establishing ground-truth geometry-based correspondences
    %       (default: 2.5 pixels)
    %     - filter_border: width of image border within which the points
    %       are filtered out to prevent access accross the image borders
    %       (default: 50 pixels)
    %
    % Output:
    %  - results: results structure, containing the following fields:
    %     - recognition_rates: RxNxP matrix of resulting recongition rates,
    %       where R is number of repetitions, N is number of descriptors,
    %       and P is number of tested image pairs
    %     - descriptor_names: copy of the input Nx1 cell array of 
    %       descriptor name strings
    %     - pairs: copy of the input image_pairs vector
    %     - sequence: copy of the input sequence name
    %
    % (C) 2015 Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
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
        recognition_rates(:,:,i) = affine_evaluate_descriptor_extractors_on_image_pair(I1, I2, H12, keypoint_detector, descriptor_extractors, keypoint_distance_threshold, num_points, num_repetitions, filter_border, visualize_sets);
    end
        
    %% Store results
    results.recognition_rates = recognition_rates;
    results.descriptor_names = descriptor_extractors(:,1);
    results.pairs = pairs;
    results.sequence = sequence;
end