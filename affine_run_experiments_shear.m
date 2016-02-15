function affine_run_experiments_shear (varargin)
    % AFFINE_RUN_EXPERIMENTS_SHEAR (varargin)
    %
    % Runs shear experiments on Affine Dataset sequences.
    %
    % Input: key/value pairs
    %  - sequences: cell array of sequence names to test on (or a single
    %    string)
    %  - image: image to rotate
    %  - shear_values: array of shear values to test
    %  - project_keypoints: whether to project keypoints instead of
    %    matching them
    %  - experiment: cell array of experiment types (or a single string)
    %  - get_experiment_fcn: function handle to function that provides
    %    experiment definitions (i.e., keypoint detector, descriptor
    %    extractors, etc. See AFFINE_GET_EXPERIMENT_DEFINITION for example)
    %  - result_dir: result directory (defualt: results-affine-rotation)
    %  - visualize: whether to visualize results or not
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>

    % Parameters
    parser = inputParser();
    parser.addParameter('sequences', { 'graffiti', 'wall' }, @(x) iscell(x) || ischar(x));
    parser.addParameter('image', 1, @isnumeric);
    parser.addParameter('shear_values', -0.65:0.05:0.65, @isnumeric);
    parser.addParameter('project_keypoints', false, @islogical);
    parser.addParameter('experiments', { 'surf-o', 'surf-u', 'sift-o', 'sift-u', 'orb', 'brisk', 'harris' }, @(x) iscell(x) || ischar(x));
    parser.addParameter('get_experiment_fcn', @affine_get_experiment_definition);
    parser.addParameter('result_dir', 'results-affine-shear', @ischar);
    parser.addParameter('visualize', false, @islogical);
    parser.parse(varargin{:});

    sequences = parser.Results.sequences;
    if ischar(sequences),
        sequences = { sequences };
    end

    image = parser.Results.image;
    shear_values = parser.Results.shear_values;
    project_keypoints = parser.Results.project_keypoints;

    experiments = parser.Results.experiments;
    if ischar(experiments),
        experiments = { experiments };
    end
    get_experiment_fcn = parser.Results.get_experiment_fcn;
    result_dir = parser.Results.result_dir;
    visualize = parser.Results.visualize;

    %% Process
    if ~exist(result_dir, 'dir'),
        mkdir(result_dir);
    end

    %% Run experiments
    for e = 1:numel(experiments),
        experiment = get_experiment_fcn(experiments{e});

        for s = 1:numel(sequences),
            sequence = sequences{s};

            experiment_name = sprintf('%s-%s', sequence, experiment.name);
            experiment_title = sprintf('%s - %s', sequence, experiment.title);

            fprintf('***** %s *****\n', experiment_title);

            % Perform experiment if necessary
            result_file = sprintf('%s.mat', experiment_name);
            result_file = fullfile(result_dir, result_file);

            if ~exist(result_file, 'file'),
                result = affine_batch_experiment_shear(experiment.keypoint_detector, experiment.descriptor_extractors, 'sequence', sequence, 'image', image, 'shear_values', shear_values, 'project_keypoints', project_keypoints, 'num_repetitions', 1, 'num_points', inf);
                result.title = experiment_title;

                save(result_file, '-struct', 'result');
            else
                fprintf('Using cached result: %s\n', result_file);
                result = load(result_file);
            end

            if visualize,
                visualize_results_shear(result);
            end
        end
    end
end
