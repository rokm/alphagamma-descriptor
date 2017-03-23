function jasna_affine_experiment (experiment_ids, varargin)
    % JASNA_AFFINE_EXPERIMENT (experiment_ids, varargin)
    
    % Parser
    parser = inputParser();
    parser.addParameter('experiment_type', 'pairs', @ischar);
    parser.addParameter('sequences', {});
    parser.addParameter('force_grayscale', true, @islogical);
    parser.addParameter('cache_dir', '', @ischar);
    parser.parse(varargin{:});
    
    experiment_type = parser.Results.experiment_type;
    sequences = parser.Results.sequences;
    force_grayscale = parser.Results.force_grayscale;
    cache_dir = parser.Results.cache_dir;
    
    % Default cache dir
    if isempty(cache_dir)
        cache_dir = '_cache_affine';
        
        if ~isequal(experiment_type, 'pairs')
            cache_dir = [ cache_dir, '-', experiment_type ];
        end
        
        if force_grayscale
            cache_dir = [ cache_dir, '-gray' ];
        end
    end
    
    % Default sequences (for non-pairs, use only graffiti)
    if isempty(sequences)
        if isequal(experiment_type, 'pairs')
            sequences = { 'bikes', 'trees', 'leuven', 'boat', 'graffiti', 'wall' };
        else
            sequences = 'graffiti';
        end
    end
    
    % If only one sequence is given, make it into cell array
    if ~iscell(sequences)
        sequences = { sequences };
    end
    
    %% Create experiment
    experiment = vicos.experiment.AffineEvaluation('cache_dir', cache_dir, 'force_grayscale', force_grayscale);

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
