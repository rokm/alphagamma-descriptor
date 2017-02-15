function jasna_dtu_experiment (experiment_ids, varargin)
    % JASNA_DTU_EXPERIMENT (experiment_ids, varargin)
    
    % Parser
    parser = inputParser();
    parser.addParameter('image_sets', [ 7, 22, 44 ], @isnumeric);
    parser.addParameter('force_grayscale', false, @islogical);
    parser.addParameter('cache_dir', '', @ischar);
    parser.parse(varargin{:});
    
    image_sets = parser.Results.image_sets;
    force_grayscale = parser.Results.force_grayscale;
    cache_dir = parser.Results.cache_dir;
    
    % Default cache dir
    if isempty(cache_dir)
        cache_dir = '_cache_dtu';
        if force_grayscale
            cache_dir = [ cache_dir, '-gray' ];
        end
    end
        
    
    %% Create DTU experiment
    dtu = vicos.experiment.DtuRobotEvaluation('cache_dir', cache_dir, 'force_grayscale', force_grayscale);

    %% Run experiment(s)
    % If only one ID is given, make it into cell array
    if ~iscell(experiment_ids)
        experiment_ids = { experiment_ids };
    end
    
    for e = 1:numel(experiment_ids)
        % Experiment parametrization
        experiment_id = experiment_ids{e};
        switch lower(experiment_id)
            case 'surf'
                keypoint_detector = vicos.keypoint_detector.SURF();
                descriptor_extractor = vicos.descriptor.SURF();
                base_keypoint_size = 17.5;
            case 'sift'
                keypoint_detector = vicos.keypoint_detector.SIFT();
                descriptor_extractor = vicos.descriptor.SIFT();
                base_keypoint_size = 3.25;
            case 'brisk'
                keypoint_detector = vicos.keypoint_detector.BRISK();
                descriptor_extractor = vicos.descriptor.BRISK();
                base_keypoint_size = 18.5;
            case 'orb'
                keypoint_detector = vicos.keypoint_detector.ORB('MaxFeatures', 7000, 'PatchSize', 18.5);
                descriptor_extractor = vicos.descriptor.ORB();
                base_keypoint_size = 18.5;
            case 'kaze'
                keypoint_detector = vicos.keypoint_detector.KAZE();
                descriptor_extractor = vicos.descriptor.KAZE('Extended', false);
                base_keypoint_size = 4.75;
            case 'radial'
                keypoint_detector = vicos.keypoint_detector.FeatureRadial('SaliencyThreshold', 0);
                descriptor_extractor = [];
                base_keypoint_size = [ 8.25, 8.0 ];
            otherwise
                error('Invalid experiment id: "%s"', experiment_id);
        end

        % If a single-value base keypoint size is provided, duplicate it
        if isscalar(base_keypoint_size)
            base_keypoint_size(2) = base_keypoint_size;
        end
    
        % Common options for alpha-gamma descriptor: orientation and scale
        % normalization, use external keypoint orientation, apply bilinear
        % sampling, use bitstrings (applicable to binarized version only)
        alphagamma_common_opts = { 'orientation_normalized', true, 'scale_normalized', true, 'compute_orientation', false, 'bilinear_sampling', true, 'use_bitstrings', true };
        alphagamma_float_opts  = [ 'identifier', 'AG', alphagamma_common_opts, { 'non_binarized_descriptor', true,  'num_rays', 13, 'num_circles',  9,  'circle_step', sqrt(2)*1.104, 'base_keypoint_size', base_keypoint_size(1) } ];
        alphagamma_ag60b_opts  = [ 'identifier', 'AG-60B', alphagamma_common_opts, { 'non_binarized_descriptor', false, 'num_rays', 23, 'num_circles', 10,  'circle_step',sqrt(2)*1.042, 'base_keypoint_size', base_keypoint_size(2) } ];

        alphagamma_float = @() vicos.descriptor.AlphaGamma(alphagamma_float_opts{:});
        alphagamma_ag60b = @() vicos.descriptor.AlphaGamma(alphagamma_ag60b_opts{:});

        % Run experiments
        for i = 1:numel(image_sets)
            image_set = image_sets(i);

            fprintf('***** Running experiments with "%s" on Sequence #%d *****\n', experiment_id, image_set);

            % Native experiment (if native descriptor extractor exists)
            if ~isempty(descriptor_extractor)
                fprintf('--- Running experiments with native descriptor ---\n');
                dtu.run_experiment(keypoint_detector, descriptor_extractor, image_set);
            end

            % AG-float
            fprintf('--- Running experiments with AG-float ---\n');
            dtu.run_experiment(keypoint_detector, alphagamma_float, image_set);

            % AG-60B
            fprintf('--- Running experiment with AG-60B ---\n');
            dtu.run_experiment(keypoint_detector, alphagamma_ag60b, image_set);
        end
    end
end