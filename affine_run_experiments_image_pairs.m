function affine_run_experiments_image_pairs (varargin)
    % AFFINE_RUN_EXPERIMENTS_IMAGE_PAIRS (varargin)
    %
    % Runs image pair experiments on Affine Dataset sequences.
    %
    % Input: key/value pairs
    %  - sequences: cell array of sequence names to test on (or a single
    %    string)
    %  - experiment: cell array of experiment types (or a single string)
    %  - get_experiment_fcn: function handle to function that provides
    %    experiment definitions (i.e., keypoint detector, descriptor
    %    extractors, etc. See AFFINE_GET_EXPERIMENT_DEFINITION for example)
    %  - result_dir: result directory (defualt: results-affine-pairs)
    %  - visualize: whether to visualize results or not
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>

    % Parameters
    parser = inputParser();
    parser.addParameter('sequences', { 'bark', 'bikes', 'boat', 'day_night', 'graffiti', 'leuven', 'trees', 'ubc', 'wall' }, @(x) iscell(x) || ischar(x));
    parser.addParameter('experiments', { 'surf-o', 'surf-u', 'sift-o', 'sift-u', 'orb', 'brisk', 'harris' }, @(x) iscell(x) || ischar(x));
    parser.addParameter('get_experiment_fcn', @affine_get_experiment_definition);
    parser.addParameter('result_dir', 'results-affine-pairs', @ischar);
    parser.addParameter('visualize', false, @islogical);
    parser.parse(varargin{:});
    
    sequences = parser.Results.sequences;
    if ischar(sequences),
        sequences = { sequences };
    end
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
                result = affine_batch_experiment_image_pairs(experiment.keypoint_detector, experiment.descriptor_extractors, 'sequence', sequence);
                result.title = experiment_title;

                save(result_file, '-struct', 'result');
            else
                fprintf('Using cached result: %s\n', result_file);
                result = load(result_file);
            end

            if visualize,
                visualize_results_image_pairs(result);
            end
        end 
    end
end