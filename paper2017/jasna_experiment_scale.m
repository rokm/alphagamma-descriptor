function jasna_experiment_scale (varargin)
    % JASNA_EXPERIMENT_SCALE (varargin)
    %
    % Performs scale experiment with SIFT keypoints and first image from
    % v_graffiti sequence in HPatches full-images dataset.
    %
    % Input:
    %  - varargin: optional key/value pairs:
    %     - force_grayscale: perform experiments on grayscale image instead
    %       of color one (default: true)
    %     - cache_dir: cache directory (default: ''; auto-generated)
    %     - display_results: display results in Matlab figure (default:
    %       false)
    %     - result_file: export results to text file (default: '';
    %       disabled)
    
    % Parser
    parser = inputParser();
    parser.addParameter('force_grayscale', true, @islogical);
    parser.addParameter('cache_dir', '', @ischar);
    parser.addParameter('display_results', false, @islogical);
    parser.addParameter('result_file', '', @ischar);
    parser.parse(varargin{:});
    
    force_grayscale = parser.Results.force_grayscale;
    cache_dir = parser.Results.cache_dir;
    display_results = parser.Results.display_results;
    result_file = parser.Results.result_file;
    
    % Default cache dir
    if isempty(cache_dir)
        cache_dir = '_cache_scale';
        if force_grayscale
            cache_dir = [ cache_dir, '-gray' ];
        end
    end
    
    %% Create experiment
    experiment = vicos.experiment.AffineEvaluation('dataset_name', 'hpatches', 'cache_dir', cache_dir, 'force_grayscale', force_grayscale);
    
    % Common parametrization for alpha-gamma descriptors
    base_keypoint_size = [ 3.25, 3.25 ];
    alphagamma_common_opts = { 'bilinear_sampling', true, 'use_bitstrings', true };
    alphagamma_float_opts  = [ alphagamma_common_opts, { 'non_binarized_descriptor', true,  'num_rays', 13, 'num_circles',  9,  'circle_step', sqrt(2)*1.104, 'base_keypoint_size', base_keypoint_size(1) } ];
    alphagamma_short_opts  = [ alphagamma_common_opts, { 'non_binarized_descriptor', false, 'num_rays', 23, 'num_circles', 10,  'circle_step', sqrt(2)*1.042, 'base_keypoint_size', base_keypoint_size(2) } ];
    
    % SIFT detector parametrizations
    sift_u_detector_fcn = @() vicos.keypoint_detector.SIFT('identifier', 'SIFT-U', 'UpRight', true);
    
    %% Process all
    experiment_ids = { ...
        'SIFT-U', sift_u_detector_fcn, @() vicos.descriptor.SIFT('identifier', 'SIFT-U');
        'BRIEF-U', sift_u_detector_fcn, @() vicos.descriptor.BRIEF('identifier', 'BRIEF-U', 'Bytes', 64, 'UseOrientation', false);
        'LATCH-U', sift_u_detector_fcn, @() vicos.descriptor.LATCH('identifier', 'LATCH-U', 'Bytes', 64, 'RotationInvariance', false);
        'AG-U',  sift_u_detector_fcn, @() vicos.descriptor.AlphaGamma('identifier', 'AG-U',  alphagamma_float_opts{:}, 'orientation_normalized', false, 'compute_orientation', false, 'scale_normalized', false);
        'AGS-U', sift_u_detector_fcn, @() vicos.descriptor.AlphaGamma('identifier', 'AGS-U', alphagamma_short_opts{:}, 'orientation_normalized', false, 'compute_orientation', false, 'scale_normalized', false);
        'AG-US',  sift_u_detector_fcn, @() vicos.descriptor.AlphaGamma('identifier', 'AG-US',  alphagamma_float_opts{:}, 'orientation_normalized', false, 'compute_orientation', false, 'scale_normalized', true);
        'AGS-US', sift_u_detector_fcn, @() vicos.descriptor.AlphaGamma('identifier', 'AGS-US', alphagamma_short_opts{:}, 'orientation_normalized', false, 'compute_orientation', false, 'scale_normalized', true);
    };
    
    scales = 0.2:0.01:2.00;
    
    % Process
    recognition_rate = cell(1, size(experiment_ids, 1));
    for s = 1:size(experiment_ids, 1)
        keypoint_detector = experiment_ids{s,2}();
        descriptor_extractor = experiment_ids{s,3}();
    
        results = experiment.run_experiment(keypoint_detector, descriptor_extractor, 'v_graffiti', 'experiment_type', 'scale', 'test_images', scales);
        
        recognition_rate{s} = [ results.num_consistent_matches ] ./ [ results.num_consistent_correspondences ];
    end
    
    %% Display
    if display_results
        figure;
        for s = 1:size(experiment_ids, 1)
            plot(scales, recognition_rate{s}, 'LineWidth', 2); hold on;
        end
        legend(experiment_ids{:,1});
    end
    
    %% Export
    if ~isempty(result_file)
        fid = fopen(result_file, 'w+');
        
        % Column names
        fprintf(fid, 'columns ');
        fprintf(fid, '%d ', 1:numel(scales));
        fprintf(fid, '\n');
        
        % Units
        fprintf(fid, 'param ');
        fprintf(fid, '%g ', scales);
        fprintf(fid, '\n');
        
        for s = 1:size(experiment_ids, 1)
            fprintf(fid, '%s ', experiment_ids{s, 1});
            fprintf(fid, '%g ', recognition_rate{s});
            fprintf(fid, '\n');
        end
        
        fclose(fid);
    end
end

