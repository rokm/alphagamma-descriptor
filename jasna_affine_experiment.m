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
    dtu = vicos.experiment.AffineEvaluation('cache_dir', cache_dir, 'force_grayscale', force_grayscale);

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
        alphagamma_float_opts  = [ 'identifier', 'AG',  alphagamma_common_opts, { 'non_binarized_descriptor', true,  'num_rays', 13, 'num_circles',  9,  'circle_step', sqrt(2)*1.104, 'base_keypoint_size', base_keypoint_size(1) } ];
        alphagamma_short_opts  = [ 'identifier', 'AGS', alphagamma_common_opts, { 'non_binarized_descriptor', false, 'num_rays', 23, 'num_circles', 10,  'circle_step', sqrt(2)*1.042, 'base_keypoint_size', base_keypoint_size(2) } ];

        alphagamma_float = @() vicos.descriptor.AlphaGamma(alphagamma_float_opts{:});
        alphagamma_short = @() vicos.descriptor.AlphaGamma(alphagamma_short_opts{:});

        % Run experiments
        for i = 1:numel(sequences)
            sequence = sequences{i};

            fprintf('***** Running experiments with "%s" on Sequence %s *****\n', experiment_id, sequence);

            % Native experiment (if native descriptor extractor exists)
            if ~isempty(descriptor_extractor)
                fprintf('--- Running experiments with native descriptor ---\n');
                dtu.run_experiment(keypoint_detector, descriptor_extractor, sequence, 'experiment_type', experiment_type);
            end

            % AG-float
            fprintf('--- Running experiments with AG-float ---\n');
            dtu.run_experiment(keypoint_detector, alphagamma_float, sequence, 'experiment_type', experiment_type);

            % AG-60B
            fprintf('--- Running experiment with AG-short ---\n');
            dtu.run_experiment(keypoint_detector, alphagamma_short, sequence, 'experiment_type', experiment_type);
        end
    end
end
