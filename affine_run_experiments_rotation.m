% AFFINE_RUN_EXPERIMENTS_ROTATION
%
% Runs all rotation experiments on Affine Dataset sequences.
%
% (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>

clear;
close all;

visualize = false;
result_dir = 'results-affine-rotation';

%sequences = { 'bark', 'bikes', 'boat', 'day_night', 'graffiti', 'leuven', 'trees', 'ubc', 'wall' };
sequences = { 'wall' };
image = 1;
angles = 0:5:180;

%% Process
if ~exist(result_dir, 'dir'),
    mkdir(result_dir);
end

for s = 1:numel(sequences),
    sequence = sequences{s};

    %% Experiment: SURF keypoints, oriented descriptors
    experiment_name = sprintf('%s-surf-oriented', sequence);
    experiment_title = sprintf('%s - SURF keypoints (oriented)', sequence);

    % Perform experiment if necessary
    result_file = sprintf('%s-results.mat', experiment_name);
    result_file = fullfile(result_dir, result_file);
    if ~exist(result_file, 'file'),
        keypoint_detector = vicos.keypoint_detector.SURF('HessianThreshold', 400, 'NOctaves', 3, 'NOctaveLayers', 4);

        descriptors = {};
        descriptors(end+1,:) = { 'SURF',  vicos.descriptor.SURF() };
        descriptors(end+1,:) = { 'O-BRIEF64', vicos.descriptor.BRIEF('Bytes', 64, 'UseOrientation', true) };
        descriptors(end+1,:) = { 'O-LATCH64', vicos.descriptor.LATCH('Bytes', 64, 'RotationInvariance', true) };

        descriptors(end+1,:) = { 'O-\alpha\gamma simple', vicos.descriptor.AlphaGamma('orientation', true, 'extended', false, 'sampling', 'simple', 'use_scale', false, 'base_sigma', sqrt(2)) };
        descriptors(end+1,:) = { 'O-\alpha\gamma C55x2', vicos.descriptor.AlphaGamma('orientation', true, 'extended', true, 'sampling', 'gaussian', 'use_scale', false) };
        descriptors(end+1,:) = { 'O-\alpha\gamma C23x2', vicos.descriptor.AlphaGamma('orientation', true, 'extended', true, 'sampling', 'gaussian', 'use_scale', false, 'num_rays', 23) };

        results = affine_batch_experiment_rotation(keypoint_detector, descriptors, 'sequence', sequence, 'image', image, 'angles', angles);
        results.title = experiment_title;

        save(result_file, '-struct', 'results');
    else
        fprintf('Using cached results: %s\n', result_file);
        results = load(result_file);
    end

    if visualize,
        visualize_results_rotation(results);
    end

    %% Experiment: SURF keypoints, unoriented descriptors
    experiment_name = sprintf('%s-surf-unoriented', sequence);
    experiment_title = sprintf('%s - SURF keypoints (unoriented)', sequence);

    % Perform experiment if necessary
    result_file = sprintf('%s-results.mat', experiment_name);
    result_file = fullfile(result_dir, result_file);
    if ~exist(result_file, 'file'),
        keypoint_detector = vicos.keypoint_detector.SURF('HessianThreshold', 400, 'NOctaves', 3, 'NOctaveLayers', 4, 'UpRight', true);

        descriptors = {};
        descriptors(end+1,:) = { 'U-SURF',  vicos.descriptor.SURF('UpRight', true) };
        descriptors(end+1,:) = { 'U-BRIEF64', vicos.descriptor.BRIEF('Bytes', 64, 'UseOrientation', false) };
        descriptors(end+1,:) = { 'U-LATCH64', vicos.descriptor.LATCH('Bytes', 64, 'RotationInvariance', false) };

        descriptors(end+1,:) = { 'U-\alpha\gamma simple', vicos.descriptor.AlphaGamma('orientation', false, 'extended', false, 'sampling', 'simple', 'use_scale', false, 'base_sigma', sqrt(2)) };
        descriptors(end+1,:) = { 'U-\alpha\gamma C55x2', vicos.descriptor.AlphaGamma('orientation', false, 'extended', true, 'sampling', 'gaussian', 'use_scale', false) };
        descriptors(end+1,:) = { 'U-\alpha\gamma C23x2', vicos.descriptor.AlphaGamma('orientation', false, 'extended', true, 'sampling', 'gaussian', 'use_scale', false, 'num_rays', 23) };

        results = affine_batch_experiment_rotation(keypoint_detector, descriptors, 'sequence', sequence, 'image', image, 'angles', angles);
        results.title = experiment_title;

        save(result_file, '-struct', 'results');
    else
        fprintf('Using cached results: %s\n', result_file);
        results = load(result_file);
    end

    if visualize,
        visualize_results_rotation(results);
    end

    %% Experiment: SURF keypoints, oriented descriptors
    experiment_name = sprintf('%s-sift-oriented', sequence);
    experiment_title = sprintf('%s - SIFT keypoints (oriented)', sequence);

    % Perform experiment if necessary
    result_file = sprintf('%s-results.mat', experiment_name);
    result_file = fullfile(result_dir, result_file);
    if ~exist(result_file, 'file'),
        keypoint_detector = vicos.keypoint_detector.SIFT();

        descriptors = {};
        descriptors(end+1,:) = { 'SIFT',  vicos.descriptor.SIFT() };
        descriptors(end+1,:) = { 'O-BRIEF64', vicos.descriptor.BRIEF('Bytes', 64, 'UseOrientation', true) };
        descriptors(end+1,:) = { 'O-LATCH64', vicos.descriptor.LATCH('Bytes', 64, 'RotationInvariance', true) };

        descriptors(end+1,:) = { 'O-\alpha\gamma simple', vicos.descriptor.AlphaGamma('orientation', true, 'extended', false, 'sampling', 'simple', 'use_scale', false, 'base_sigma', sqrt(2)) };
        descriptors(end+1,:) = { 'O-\alpha\gamma C55x2', vicos.descriptor.AlphaGamma('orientation', true, 'extended', true, 'sampling', 'gaussian', 'use_scale', false) };
        descriptors(end+1,:) = { 'O-\alpha\gamma C23x2', vicos.descriptor.AlphaGamma('orientation', true, 'extended', true, 'sampling', 'gaussian', 'use_scale', false, 'num_rays', 23) };

        results = affine_batch_experiment_rotation(keypoint_detector, descriptors, 'sequence', sequence, 'image', image, 'angles', angles);
        results.title = experiment_title;

        save(result_file, '-struct', 'results');
    else
        fprintf('Using cached results: %s\n', result_file);
        results = load(result_file);
    end

    if visualize,
        visualize_results_rotation(results);
    end
    
    %% Experiment: SIFT keypoints, unoriented descriptors
    experiment_name = sprintf('%s-sift-unoriented', sequence);
    experiment_title = sprintf('%s - SIFT keypoints (unoriented)', sequence);

    % Perform experiment if necessary
    result_file = sprintf('%s-results.mat', experiment_name);
    result_file = fullfile(result_dir, result_file);
    if ~exist(result_file, 'file'),
        keypoint_detector = vicos.keypoint_detector.SIFT('UpRight', true);

        descriptors = {};
        descriptors(end+1,:) = { 'U-SIFT',  vicos.descriptor.SIFT() };
        descriptors(end+1,:) = { 'U-BRIEF64', vicos.descriptor.BRIEF('Bytes', 64, 'UseOrientation', false) };
        descriptors(end+1,:) = { 'U-LATCH64', vicos.descriptor.LATCH('Bytes', 64, 'RotationInvariance', false) };

        descriptors(end+1,:) = { 'U-\alpha\gamma simple', vicos.descriptor.AlphaGamma('orientation', false, 'extended', false, 'sampling', 'simple', 'use_scale', false, 'base_sigma', sqrt(2)) };
        descriptors(end+1,:) = { 'U-\alpha\gamma C55x2', vicos.descriptor.AlphaGamma('orientation', false, 'extended', true, 'sampling', 'gaussian', 'use_scale', false) };
        descriptors(end+1,:) = { 'U-\alpha\gamma C23x2', vicos.descriptor.AlphaGamma('orientation', false, 'extended', true, 'sampling', 'gaussian', 'use_scale', false, 'num_rays', 23) };

        results = affine_batch_experiment_rotation(keypoint_detector, descriptors, 'sequence', sequence, 'image', image, 'angles', angles);
        results.title = experiment_title;

        save(result_file, '-struct', 'results');
    else
        fprintf('Using cached results: %s\n', result_file);
        results = load(result_file);
    end

    if visualize,
        visualize_results_rotation(results);
    end
end
