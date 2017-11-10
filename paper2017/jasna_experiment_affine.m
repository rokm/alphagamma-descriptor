function jasna_experiment_affine (experiment_ids, varargin)
    % JASNA_EXPERIMENT_AFFINE (experiment_ids, varargin)
    %
    % Runs the experiments on the Oxford dataset.
    %
    % Input:
    %  - experiment_ids: cell array of experiment IDs (for list of valid
    %    IDs, see JASNA_GET_EXPERIMENT_DEFINITION())
    %  - varargin: optional key/value pairs:
    %     - dataset: 'affine' or 'hpatches' (default: 'affine')
    %     - experiment_type: experiment type (default: pairs)
    %     - sequences: sequences to process (default: { 'bikes', 'trees', 
    %       'leuven', 'boat', 'graffiti', 'wall' } for pairs experiment,
    %       'graffiti' for others)
    %     - force_grayscale: perform experiments on grayscale images
    %       instead of color ones (default: true)
    %     - cache_dir: cache directory (default: ''; auto-generated)
    %
    % Running the experiments will produce results files inside the cache
    % directory. To visualize the results, use JASNA_DISPLAY_RESULTS()
    % function.
    
    % Parser
    parser = inputParser();
    parser.addParameter('dataset', 'affine', @ischar);
    parser.addParameter('experiment_type', 'pairs', @ischar);
    parser.addParameter('sequences', {});
    parser.addParameter('force_grayscale', true, @islogical);
    parser.addParameter('cache_dir', '', @ischar);
    parser.parse(varargin{:});
    
    dataset = parser.Results.dataset;
    experiment_type = parser.Results.experiment_type;
    sequences = parser.Results.sequences;
    force_grayscale = parser.Results.force_grayscale;
    cache_dir = parser.Results.cache_dir;
    
    % Default cache dir
    if isempty(cache_dir)
        cache_dir = sprintf('_cache_%s', dataset);
        
        if ~isequal(experiment_type, 'pairs')
            cache_dir = [ cache_dir, '-', experiment_type ];
        end
        
        if force_grayscale
            cache_dir = [ cache_dir, '-gray' ];
        end
    end
        
    %% Create experiment
    experiment = vicos.experiment.AffineEvaluation('dataset_name', dataset, 'cache_dir', cache_dir, 'force_grayscale', force_grayscale);
    
    %% Determine sequences
    % Default sequences (for non-pairs, use only graffiti)
    if isempty(sequences)
        if isequal(experiment_type, 'pairs')
            sequences = { 'bikes', 'trees', 'leuven', 'boat', 'graffiti', 'wall' };
        else
            sequences = 'graffiti';
        end
    elseif isequal(sequences, '*')
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
                experiment.run_experiment(keypoint_detector, descriptor_extractor, sequence, 'experiment_type', experiment_type);
            end

            % AG-float
            fprintf('--- Running experiments with AG-float ---\n');
            experiment.run_experiment(keypoint_detector, alphagamma_float, sequence, 'experiment_type', experiment_type);

            % AG-short
            fprintf('--- Running experiment with AG-short ---\n');
            experiment.run_experiment(keypoint_detector, alphagamma_short, sequence, 'experiment_type', experiment_type);
        end
    end
end
