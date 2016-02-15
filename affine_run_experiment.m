function affine_run_experiment (experiment_type, experiment_definitions, varargin)
    % results = AFFINE_BATCH_EXPERIMENT_IMAGE_PAIRS (keypoint_detector, descriptor_extractors, varargin)
    %
    % Batch experiments on Oxford Affine dataset.
    %
    % Input:
    %  - experiment_type: experiment type:
    %     - 'pairs': image pairs
    %     - 'rotation': rotation  of the specified image
    %     - 'scale': scaling of the specified image
    %     - 'shear': shear on the specified image
    %  - experiment_definitions: an array of structures, containing the
    %    definitions of experiments, each comprising a keypoint detector
    %    and one or more descriptor extractors. Each structure in array
    %    must contain the following fields:
    %     - title: descriptive experiment title (shown on plots)
    %     - name: short experiment name (used for cache filenames)
    %     - keypoint_detector_fcn: function handle that creates the 
    %       keypoint detector instance (vicos.keypoint_detector.KeypointDetector)
    %     - descriptors: a structure array with following fields:
    %        - name: descriptor extractor name (shown on plots)
    %        - create_fcn: function handle that creates the descriptor
    %          extractor instance (vicos.descriptor.Descriptor)
    %  - varargin: optional key/value pairs:
    %     - sequences: name(s) of sequences (cell array or a string) on
    %       which each experiment is to be run (default: all sequences from
    %       Oxford Affine dataset)
    %     - results_dir: results directory (default: affine-results, plus 
    %       experiment_type string)
    %     - display_results: whether to display results after each
    %       experiment is complete (default: false)
    %     - base_image: base image to use in experiments; for 'pairs'
    %       experiment, this value must be 1, otherwise, it denotes the
    %       image on which transformations are performed (default: 1)
    %     - values: array of values used in experiment. The meaning depends
    %       on experiment type:
    %        - 'pairs': numbers of the other image in pairs (default: [ 2, 3, 4, 5, 6 ])
    %        - 'rotation': rotation angles, in degrees (default: -180:5:180)
    %        - 'scale': scale factors (default: 0.50:0.05:1.50)
    %        - 'shear': shear factors, in both x and y direction (default: -0.65:0.05:0.65)
    %     - num_points: number of point correspondences to randomly sample
    %       if more correspondences are obtained. Set to inf if all points
    %       are to be used (default: 1000)
    %     - num_repetitions: number of repetitions (default: 5)
    %     - keypoint_distance_threshold: distance threshold used when
    %       establishing ground-truth geometry-based correspondences
    %       (default: 2.5 pixels)
    %     - filter_border: width of image border within which the points
    %       are filtered out to prevent access accross the image borders
    %       (default: 50 pixels)
    %     - project_keypoints: if set to false (default), keypoints are
    %       detected in both images and matched via homography and distance
    %       constraints. If set to true, the keypoints are detected only in
    %       the first image, and directly projected to the second image
    %       using the homography. Useful for mitigating effects of poor
    %       keypoint localization on descriptor's performance.
    %     - visualize_sets: visualize the correspondence sets (each drawn
    %       set in a separate figure) (default: false)
    %
    % As an output, a results structure is created and stored in the cache
    % file for later visualization. The structure contains the following
    % fields:
    %  - type: experiment type string
    %  - experiment: a copy of the input 'experiment_type' structure array
    %  - recognition_rates: RxNxP matrix of resulting recongition rates,
    %    where R is number of repetitions, N is number of descriptors,
    %    and P is number of tested image pairs
    %  - base_image: base image (copied from input parameters)
    %  - values: values used in experiment (copied from input parameters)
    %  - sequence: sequence name
    %  - num_keypoints1: Px1 vector of numbers of keypoints detected in 
    %    the first image(s)
    %  - num_keypoints2: Px1 vector of numbers of keypoints detectd in
    %    the second image(s)
    %  - num_established_correspondences: Px1 vector of numbers of 
    %    correspondences established between the two sets of keypoints
    %  - num_requested_correspondences: number of requested 
    %    correspondences (copy of the num_points parameter)
    %
    % (C) 2015-2016 Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>

    %% Parameters
    parser = inputParser();
    parser.addParameter('sequences', { 'bark', 'bikes', 'boat', 'day_night', 'graffiti', 'leuven', 'trees', 'ubc', 'wall' }, @(x) iscell(x) || ischar(x));
    parser.addParameter('results_dir', '', @ischar);
    parser.addParameter('display_results', false, @islogical);
    parser.addParameter('base_image', 1, @isnumeric);
    parser.addParameter('values', [], @isnumeric);
    parser.addParameter('num_points', 1000, @isscalar);
    parser.addParameter('num_repetitions', 5, @isscalar);
    parser.addParameter('keypoint_distance_threshold', 2.5, @isnumeric);
    parser.addParameter('filter_border', 50, @isnumeric);
    parser.addParameter('project_keypoints', false, @islogical);
    parser.addParameter('visualize_sets', false, @islogical);
    parser.parse(varargin{:});
    
    sequences = parser.Results.sequences;
    results_dir = parser.Results.results_dir;
    display_results = parser.Results.display_results;

    base_image = parser.Results.base_image;
    values = parser.Results.values;
    
    num_points = parser.Results.num_points;
    num_repetitions = parser.Results.num_repetitions;

    keypoint_distance_threshold = parser.Results.keypoint_distance_threshold;
    filter_border = parser.Results.filter_border;
    project_keypoints = parser.Results.project_keypoints;
    
    visualize_sets = parser.Results.visualize_sets;
    
    % Validate experiment type
    assert(ismember(experiment_type, { 'pairs', 'rotation', 'scale', 'shear' }), 'Invalid experiment type: %s!', experiment_type);
    
    % Handle cases when only a single sequence name is given
    if ischar(sequences),
        sequences = { sequences };
    end
    
    % Default results dir name (based on experiment type)
    if isempty(results_dir),
        results_dir = sprintf('results-affine-%s', experiment_type);
    end
    
    % Default values for different experiment types
    if isempty(values),
        switch experiment_type,
            case 'pairs',
                values = [ 2, 3, 4, 5, 6 ]; % Image pairs
            case 'rotation',
                values = -180:5:180; % Rotation angles
            case 'scale',
                values = 0.50:0.05:1.50; % Scale factors
            case 'shear',
                values = -0.65:0.05:0.65; % Shear factors
        end
    end
    
    num_values = numel(values);
    
    %% Create results directory    
    if ~exist(results_dir, 'dir'),
        mkdir(results_dir);
    end
    
    %% Process
    dataset = AffineDataset();
    
    % All experiments ...
    for e = 1:numel(experiment_definitions),
        experiment = experiment_definitions(e);
        
        % ... over all sequences
        for s = 1:numel(sequences),
            sequence = sequences{s};

            fprintf('*** %s - %s ***\n', sequence, experiment.title);

            % Perform experiment if necessary
            results_file = sprintf('%s-%s.mat', sequence, experiment.name);
            results_file = fullfile(results_dir, results_file);

            if ~exist(results_file, 'file'),
                %% Create keypoint detector
                keypoint_detector = experiment.keypoint_detector_fcn();
                
                %% Create descriptor extractors
                descriptor_extractors = cell(numel(experiment.descriptors), 2);
                for d = 1:numel(experiment.descriptors),
                    descriptor_extractors(d,:) = { experiment.descriptors(d).name, experiment.descriptors(d).create_fcn() };
                end
                
                %% Run experiment
                recognition_rates = nan(num_repetitions, size(descriptor_extractors, 1), num_values);
                num_keypoints1 = nan(num_values, 1);
                num_keypoints2 = nan(num_values, 1);
                num_established_correspondences = nan(num_values, 1);
    
                % ... over all specified values (pairs/angles/scales/etc.)
                for i = 1:num_values,
                    % Generate image pair according to experiment type
                    switch experiment_type,
                        case 'pairs',
                            fprintf('\n--- Image pair #%d/%d: %d|%d ---\n', i, num_values, base_image, values(i));
                            [ I1, I2, H12 ] = dataset.get_image_pair(sequence, base_image, values(i));
                        case 'rotation',
                            fprintf('\n--- Angle #%d/%d: %f deg ---\n', i, num_values, values(i));
                            [ I1, I2, H12 ] = dataset.get_rotated_image(sequence, base_image, values(i));
                        case 'scale',
                            fprintf('\n--- Scale #%d/%d: %f ---\n', i, num_values, values(i));
                            [ I1, I2, H12 ] = dataset.get_scaled_image(sequence, base_image, values(i));
                        case 'shear',
                            fprintf('\n--- Shear #%d/%d: %f ---\n', i, num_values, values(i));
                            [ I1, I2, H12 ] = dataset.get_sheared_image(sequence, base_image, values(i), values(i));
                    end

                    % Evaluate performance on the given image pair
                    [ recognition_rates(:,:,i), num_keypoints1(i), num_keypoints2(i), num_established_correspondences(i) ] = affine_evaluate_descriptor_extractors_on_image_pair(I1, I2, H12, keypoint_detector, descriptor_extractors, project_keypoints, keypoint_distance_threshold, num_points, num_repetitions, filter_border, visualize_sets);
                end
        
                %% Store results
                results.type = experiment_type;
                results.experiment = experiment;
                
                results.recognition_rates = recognition_rates;
                results.base_image = base_image;
                results.values = values;
                results.sequence = sequence;
    
                results.num_keypoints1 = num_keypoints1;
                results.num_keypoints2 = num_keypoints2;
                results.num_established_correspondences = num_established_correspondences;
                results.num_requested_correspondences = num_points;
    
                save(results_file, '-struct', 'results');
            else
                fprintf('Using cached results: %s\n', results_file);
                results = load(results_file);
            end

            if display_results,
                affine_display_results(results);
            end
        end 
    end
end