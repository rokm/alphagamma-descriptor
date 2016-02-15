function affine_run_experiment (experiment_type, experiment_definitions, varargin)
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