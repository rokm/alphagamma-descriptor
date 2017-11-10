function jasna_experiment_webcam (experiment_ids, varargin)
    % JASNA_EXPERIMENT_WEBCAM (experiment_ids, varargin)
    %
    % Runs the experiments on the WebCam dataset.
    %
    % Input:
    %  - experiment_ids: cell array of experiment IDs (for list of valid
    %    IDs, see JASNA_GET_EXPERIMENT_DEFINITION())
    %  - varargin: optional key/value pairs:
    %     - sequences: sequences to process (default: Frankfurt)
    %     - force_grayscale: perform experiments on grayscale images
    %       instead of color ones (default: true)
    %     - cache_dir: cache directory (default: ''; auto-generated)
    %
    % Running the experiments will produce results files inside the cache
    % directory. To visualize the results, use JASNA_DISPLAY_RESULTS()
    % function.
    
    % Parser
    parser = inputParser();
    parser.addParameter('sequences', 'Frankfurt');
    parser.addParameter('force_grayscale', true, @islogical);
    parser.addParameter('cache_dir', '', @ischar);
    parser.parse(varargin{:});
    
    sequences = parser.Results.sequences;
    force_grayscale = parser.Results.force_grayscale;
    cache_dir = parser.Results.cache_dir;
    
    % Default cache dir
    if isempty(cache_dir)
        cache_dir = '_cache_webcam';
        if force_grayscale
            cache_dir = [ cache_dir, '-gray' ];
        end
    end
    
    %% Create experiment
    experiment = vicos.experiment.WebcamEvaluation('cache_dir', cache_dir, 'force_grayscale', force_grayscale);

    %% Determine sequences
    if isequal(sequences, '*')
        % Wildcard support: use all sequences
        sequences = experiment.list_all_sequences();
    end
    
    % If only one sequence is given, make it into cell array
    if ~iscell(sequences)
        sequences = { sequences };
    end
    
    %% Run experiment(s)
    % If only one ID is given, make it into cell array
    if ~iscell(experiment_ids)
        experiment_ids = { experiment_ids };
    end
    
    for e = 1:numel(experiment_ids)
        % Experiment parametrization
        experiment_id = experiment_ids{e};
        [ keypoint_detector, descriptor_extractor, alphagamma_float, alphagamma_short ] = jasna_get_experiment_definition(experiment_id);

        % Run experiments
        for i = 1:numel(sequences)
            sequence = sequences{i};

            fprintf('***** Running experiments with "%s" on Sequence %s *****\n', experiment_id, sequence);

            % Native experiment (if native descriptor extractor exists)
            if ~isempty(descriptor_extractor)
                fprintf('--- Running experiments with native descriptor ---\n');
                experiment.run_experiment(keypoint_detector, descriptor_extractor, sequence);
            end

            % AG-float
            fprintf('--- Running experiments with AG-float ---\n');
            experiment.run_experiment(keypoint_detector, alphagamma_float, sequence);

            % AG-short
            fprintf('--- Running experiment with AG-short ---\n');
            experiment.run_experiment(keypoint_detector, alphagamma_short, sequence);
        end
    end
end
