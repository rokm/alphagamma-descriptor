function jasna_experiment_dtu (experiment_ids, varargin)
    % JASNA_EXPERIMEN_DTU (experiment_ids, varargin)
    %
    % Runs the experiments on the DTU dataset sequences.
    %
    % Input:
    %  - experiment_ids: cell array of experiment IDs (for list of valid
    %    IDs, see JASNA_GET_EXPERIMENT_DEFINITION())
    %  - varargin: optional key/value pairs:
    %     - image_sets: sequences to process - array of sequence numbers
    %       (e.g, [ 7, 22, 23, 49 ]) or '*' to use all available (default)
    %     - force_grayscale: perform experiments on grayscale images
    %       instead of color ones (default: true)
    %     - cache_dir: cache directory (default: ''; auto-generated)
    %     - max_keypoints: maximum number of keypoints (default: inf)
    %     - half_size_images: use half-size (800x600) dataset images
    %      (default: false)
    %
    % Running the experiments will produce results files inside the cache
    % directory. To visualize the results, use JASNA_DISPLAY_RESULTS()
    % function.

    % Parser
    parser = inputParser();
    parser.addParameter('image_sets', '*');
    parser.addParameter('force_grayscale', true, @islogical);
    parser.addParameter('cache_dir', '', @ischar);
    parser.addParameter('max_keypoints', inf, @isnumeric);
    parser.addParameter('half_size_images', false, @islogical);
    parser.parse(varargin{:});

    image_sets = parser.Results.image_sets;
    force_grayscale = parser.Results.force_grayscale;
    cache_dir = parser.Results.cache_dir;
    max_keypoints = parser.Results.max_keypoints;
    half_size_images = parser.Results.half_size_images;

    % Default cache dir
    if isempty(cache_dir)
        cache_dir = '_cache_dtu';
        if force_grayscale
            cache_dir = [ cache_dir, '-gray' ];
        end
    end

    %% Create experiment
    experiment = vicos.experiment.DtuRobotEvaluation('cache_dir', cache_dir, 'force_grayscale', force_grayscale, 'max_keypoints', max_keypoints, 'half_size_images', half_size_images);

    %% Determine image sets
    if isequal(image_sets, '*')
        % Wildcard support: use all image sets
        image_sets = experiment.list_all_sequences();
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
        for i = 1:numel(image_sets)
            image_set = image_sets(i);

            fprintf('***** Running experiments with "%s" on Sequence #%d *****\n', experiment_id, image_set);

            % Native experiment (if native descriptor extractor exists)
            if ~isempty(descriptor_extractor)
                fprintf('--- Running experiments with native descriptor ---\n');
                experiment.run_experiment(keypoint_detector, descriptor_extractor, image_set);
            end

            % AG-float
            if ~isempty(alphagamma_float)
                fprintf('--- Running experiments with AG-float ---\n');
                experiment.run_experiment(keypoint_detector, alphagamma_float, image_set);
            end

            % AG-short
            if ~isempty(alphagamma_short)
                fprintf('--- Running experiment with AG-short ---\n');
                experiment.run_experiment(keypoint_detector, alphagamma_short, image_set);
            end
        end
    end
end
