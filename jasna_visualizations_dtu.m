function jasna_visualizations_dtu (varargin)          
    % Parser
    parser = inputParser();
    parser.addParameter('experiment_ids', {});
    parser.addParameter('sequences', {});
    parser.addParameter('force_grayscale', true, @islogical);
    parser.addParameter('cache_dir', '', @ischar);
    parser.parse(varargin{:});
    
    experiment_ids = parser.Results.experiment_ids;
    sequences = parser.Results.sequences;
    force_grayscale = parser.Results.force_grayscale;
    cache_dir = parser.Results.cache_dir;
    
    % Default cache dir
    if isempty(cache_dir)
        cache_dir = '_visualization_dtu';
        
        if force_grayscale
            cache_dir = [ cache_dir, '-gray' ];
        end
    end
    
    % Default experiments: all
    if isempty(experiment_ids)
        experiment_ids = { 'sift', 'surf', 'kaze', 'brisk', 'orb', 'radial' };
    end
    
    % Default sequences
    if isempty(sequences)
        sequences = { 10, 25, 119;
                      19, 25,   1;
                      21, 25, 119 };
    end
    
    % Additional visualization parameters
    visualization_parameters = { 'image_scale', 0.5, 'caption_color', 'green' };
    
    %% Create experiment
    experiment = vicos.experiment.DtuRobotEvaluation('cache_dir', cache_dir, 'force_grayscale', force_grayscale);

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
        for i = 1:size(sequences, 1)
            sequence = sequences{i, 1};
            ref_image = sequences{i, 2};
            test_image = sequences{i, 3};

            fprintf('***** Running experiments with "%s" on Sequence SET%d, %d -> %d *****\n', experiment_id, sequence, ref_image, test_image);

            % Native experiment (if native descriptor extractor exists)
            if ~isempty(descriptor_extractor)
                fprintf('--- Running experiments with native descriptor ---\n');
                experiment.run_experiment(keypoint_detector, descriptor_extractor, sequence, 'reference_image', ref_image, 'test_images', test_image, 'visualize_matches', true, 'visualization_parameters', visualization_parameters);
            end

            % AG-float
            fprintf('--- Running experiments with AG-float ---\n');
            experiment.run_experiment(keypoint_detector, alphagamma_float, sequence, 'reference_image', ref_image, 'test_images', test_image, 'visualize_matches', true, 'visualization_parameters', visualization_parameters);

            % AG-60B
            fprintf('--- Running experiment with AG-short ---\n');
            experiment.run_experiment(keypoint_detector, alphagamma_short, sequence, 'reference_image', ref_image, 'test_images', test_image, 'visualize_matches', true, 'visualization_parameters', visualization_parameters);
        end
    end
end
