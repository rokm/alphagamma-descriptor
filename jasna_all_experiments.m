% JASNA_ALL_EXPERIMENTS
%
% All experiments for the PAMI paper.

%% Settings
%results_prefix = 'results-final';
%num_points = 1000;
%num_repetitions = 5;

results_prefix = 'results-final-inf';
num_points = inf;
num_repetitions = 1;

display_results = false;


%% Common descriptor definitions
def_o_brief64 = { 'Bytes', 64, 'UseOrientation', true };
def_u_brief64 = { 'Bytes', 64, 'UseOrientation', false };

def_o_latch64 = { 'Bytes', 64, 'RotationInvariance', true };
def_u_latch64 = { 'Bytes', 64, 'RotationInvariance', false };

def_u_freak = { 'OrientationNormalized', false, 'ScaleNormalized', false };
def_o_freak = { 'OrientationNormalized', true, 'ScaleNormalized', false };
def_su_freak = { 'OrientationNormalized', false, 'ScaleNormalized', true };
def_so_freak = { 'OrientationNormalized', true, 'ScaleNormalized', true };

def_u_ag_basic = { 'orientation', false, 'num_rays', 41, 'num_circles', 12, 'compute_extended', false, 'sampling', 'simple', 'use_scale', false, 'base_sigma', sqrt(2) };
def_o_ag_basic = { 'orientation', true,  'num_rays', 41, 'num_circles', 12, 'compute_extended', false, 'sampling', 'simple', 'use_scale', false, 'base_sigma', sqrt(2) };

def_u_ag_23x2_10 = { 'orientation', false, 'num_rays', 23, 'num_circles', 10, 'circle_step', 1.042*sqrt(2) };
def_o_ag_23x2_10 = { 'orientation', true,  'num_rays', 23, 'num_circles', 10, 'circle_step', 1.042*sqrt(2) };

def_su_ag_23x2_10 = { 'orientation', false, 'num_rays', 23, 'num_circles', 10, 'circle_step', 1.042*sqrt(2), 'use_scale', true };
def_so_ag_23x2_10 = { 'orientation', true,  'num_rays', 23, 'num_circles', 10, 'circle_step', 1.042*sqrt(2), 'use_scale', true };

def_u_ag_13x2_9 = { 'orientation', false, 'num_rays', 13, 'num_circles', 9, 'circle_step', 1.104*sqrt(2) };
def_o_ag_13x2_9 = { 'orientation', true,  'num_rays', 13, 'num_circles', 9, 'circle_step', 1.104*sqrt(2) };

def_su_ag_13x2_9 = { 'orientation', false, 'num_rays', 13, 'num_circles', 9, 'circle_step', 1.104*sqrt(2), 'use_scale', true };
def_so_ag_13x2_9 = { 'orientation', true,  'num_rays', 13, 'num_circles', 9, 'circle_step', 1.104*sqrt(2), 'use_scale', true };

%% Experiment 1: unoriented descriptors test
sequences = { 'graffiti', 'wall', 'boat' };
results_dir = fullfile(results_prefix, 'pairs-unoriented');

% Define experiments
experiments = define_experiment();

experiments(end+1) = define_experiment(...
    'u-surf', ...
    'SURF keypoints (unoriented)', ...
    @() vicos.keypoint_detector.SURF('HessianThreshold', 400, 'NOctaves', 3, 'NOctaveLayers', 4, 'UpRight', true), ...
    'U-SURF', @() vicos.descriptor.SURF('UpRight', true), ...
    'U-BRIEF64', @() vicos.descriptor.BRIEF(def_u_brief64{:}), ...
    'U-LATCH64', @() vicos.descriptor.LATCH(def_u_latch64{:}), ...
    'U-FREAK', @() vicos.descriptor.FREAK(def_u_freak{:}), ...
    'SU-FREAK', @() vicos.descriptor.FREAK(def_su_freak{:}, 'PatternScale', 15), ...
    'U-AG basic', @() vicos.descriptor.AlphaGamma(def_u_ag_basic{:}), ...
    'U-AG60', @() vicos.descriptor.AlphaGamma(def_u_ag_23x2_10{:}), ...
    'SU-AG60', @() vicos.descriptor.AlphaGamma(def_su_ag_23x2_10{:}, 'base_keypoint_size', 18.5) ...
    );

experiments(end+1) = define_experiment(...
    'u-sift', ...
    'SIFT keypoints (unoriented)', ...
    @() vicos.keypoint_detector.SIFT('UpRight', true), ...
    'U-SIFT', @() vicos.descriptor.SIFT('UpRight', true), ...
    'U-BRIEF64', @() vicos.descriptor.BRIEF(def_u_brief64{:}), ...
    'U-LATCH64', @() vicos.descriptor.LATCH(def_u_latch64{:}), ...
    'U-FREAK', @() vicos.descriptor.FREAK(def_u_freak{:}), ...
    'SU-FREAK', @() vicos.descriptor.FREAK(def_su_freak{:}, 'PatternScale', 45), ...
    'U-AG basic', @() vicos.descriptor.AlphaGamma(def_u_ag_basic{:}), ...
    'U-AG60', @() vicos.descriptor.AlphaGamma(def_u_ag_23x2_10{:}), ...
    'SU-AG60', @() vicos.descriptor.AlphaGamma(def_su_ag_23x2_10{:}, 'base_keypoint_size', 3.25) ...
    );

experiments(end+1) = define_experiment(...
    'u-orb', ...
    'ORB keypoints (unoriented)', ...
    @() vicos.keypoint_detector.ORB('MaxFeatures', 3000, 'PatchSize', 18.5, 'UpRight', true), ... % Default patch size is around 30
    'U-ORB32', @() vicos.descriptor.ORB(), ...
    'U-BRIEF64', @() vicos.descriptor.BRIEF(def_u_brief64{:}), ...
    'U-LATCH64', @() vicos.descriptor.LATCH(def_u_latch64{:}), ...
    'U-FREAK', @() vicos.descriptor.FREAK(def_u_freak{:}), ...
    'SU-FREAK', @() vicos.descriptor.FREAK(def_su_freak{:}, 'PatternScale', 15), ...
    'U-AG basic', @() vicos.descriptor.AlphaGamma(def_u_ag_basic{:}), ...
    'U-AG60', @() vicos.descriptor.AlphaGamma(def_u_ag_23x2_10{:}), ...
    'SU-AG60', @() vicos.descriptor.AlphaGamma(def_su_ag_23x2_10{:}, 'base_keypoint_size', 18.5) ...
    );

experiments(end+1) = define_experiment(...
    'u-brisk', ...
    'BRISK keypoints (unoriented)', ...
    @() vicos.keypoint_detector.BRISK('Threshold', 60, 'UpRight', true), ...
    'U-BRISK', @() vicos.descriptor.BRISK(), ...
    'U-BRIEF64', @() vicos.descriptor.BRIEF(def_u_brief64{:}), ...
    'U-LATCH64', @() vicos.descriptor.LATCH(def_u_latch64{:}), ...
    'U-FREAK', @() vicos.descriptor.FREAK(def_u_freak{:}), ...
    'SU-FREAK', @() vicos.descriptor.FREAK(def_su_freak{:}, 'PatternScale', 22), ...
    'U-AG basic', @() vicos.descriptor.AlphaGamma(def_u_ag_basic{:}), ...
    'U-AG60', @() vicos.descriptor.AlphaGamma(def_u_ag_23x2_10{:}), ...
    'SU-AG60', @() vicos.descriptor.AlphaGamma(def_su_ag_23x2_10{:}, 'base_keypoint_size', 18.5) ...
    );

experiments(end+1) = define_experiment(...
    'u-kaze', ...
    'KAZE keypoints (unoriented)', ...
    @() vicos.keypoint_detector.KAZE('Upright', true), ...
    'U-KAZE64', @() vicos.descriptor.KAZE('Upright', true, 'Extended', false), ...
    'U-BRIEF64', @() vicos.descriptor.BRIEF(def_u_brief64{:}), ...
    'U-LATCH64', @() vicos.descriptor.LATCH(def_u_latch64{:}), ...
    'U-FREAK', @() vicos.descriptor.FREAK(def_u_freak{:}), ...
    'SU-FREAK', @() vicos.descriptor.FREAK(def_su_freak{:}, 'PatternScale', 45), ...
    'U-AG basic', @() vicos.descriptor.AlphaGamma(def_u_ag_basic{:}), ...
    'U-AG60', @() vicos.descriptor.AlphaGamma(def_u_ag_23x2_10{:}), ...
    'SU-AG60', @() vicos.descriptor.AlphaGamma(def_su_ag_23x2_10{:}, 'base_keypoint_size', 6.5) ...
    );

% Run
affine_run_experiment('pairs', experiments, 'sequences', sequences, 'results_dir', results_dir, 'num_repetitions', num_repetitions, 'num_points', num_points, 'display_results', display_results);

%% Experiment2: orientation and scale
sequences = { 'graffiti', 'wall', 'boat' };
results_dir = fullfile(results_prefix, 'pairs-oriented');

% Define experiments
experiments = define_experiment();

experiments(end+1) = define_experiment(...
    'surf', ...
    'SURF keypoints (oriented)', ...
    @() vicos.keypoint_detector.SURF('HessianThreshold', 400, 'NOctaves', 3, 'NOctaveLayers', 4), ...
    'O-SURF', @() vicos.descriptor.SURF(), ...
    'O-BRIEF64', @() vicos.descriptor.BRIEF(def_o_brief64{:}), ...
    'O-LATCH64', @() vicos.descriptor.LATCH(def_o_latch64{:}), ...
    'O-FREAK', @() vicos.descriptor.FREAK(def_o_freak{:}), ...
    'SO-FREAK', @() vicos.descriptor.FREAK(def_so_freak{:}, 'PatternScale', 15), ...
    'O-AG basic', @() vicos.descriptor.AlphaGamma(def_o_ag_basic{:}), ...
    'O-AG60', @() vicos.descriptor.AlphaGamma(def_o_ag_23x2_10{:}), ...
    'SO-AG60', @() vicos.descriptor.AlphaGamma(def_so_ag_23x2_10{:}, 'base_keypoint_size', 18.5) ...
    );

experiments(end+1) = define_experiment(...
    'sift', ...
    'SIFT keypoints (oriented)', ...
    @() vicos.keypoint_detector.SIFT(), ...
    'O-SIFT', @() vicos.descriptor.SIFT(), ...
    'O-BRIEF64', @() vicos.descriptor.BRIEF(def_o_brief64{:}), ...
    'O-LATCH64', @() vicos.descriptor.LATCH(def_o_latch64{:}), ...
    'O-FREAK', @() vicos.descriptor.FREAK(def_o_freak{:}), ...
    'SO-FREAK', @() vicos.descriptor.FREAK(def_so_freak{:}, 'PatternScale', 45), ...
    'O-AG basic', @() vicos.descriptor.AlphaGamma(def_o_ag_basic{:}), ...
    'O-AG60', @() vicos.descriptor.AlphaGamma(def_o_ag_23x2_10{:}), ...
    'SO-AG60', @() vicos.descriptor.AlphaGamma(def_so_ag_23x2_10{:}, 'base_keypoint_size', 3.25) ...
    );

experiments(end+1) = define_experiment(...
    'orb', ...
    'ORB keypoints', ...
    @() vicos.keypoint_detector.ORB('MaxFeatures', 3000, 'PatchSize', 18.5), ... % Default patch size is around 30
    'O-ORB32', @() vicos.descriptor.ORB(), ...
    'O-BRIEF64', @() vicos.descriptor.BRIEF(def_o_brief64{:}), ...
    'O-LATCH64', @() vicos.descriptor.LATCH(def_o_latch64{:}), ...
    'O-FREAK', @() vicos.descriptor.FREAK(def_o_freak{:}), ...
    'SO-FREAK', @() vicos.descriptor.FREAK(def_so_freak{:}, 'PatternScale', 15), ...
    'O-AG basic', @() vicos.descriptor.AlphaGamma(def_o_ag_basic{:}), ...
    'O-AG60', @() vicos.descriptor.AlphaGamma(def_o_ag_23x2_10{:}), ...
    'SO-AG60', @() vicos.descriptor.AlphaGamma(def_so_ag_23x2_10{:}, 'base_keypoint_size', 18.5) ...
    );

experiments(end+1) = define_experiment(...
    'brisk', ...
    'BRISK keypoints (oriented)', ...
    @() vicos.keypoint_detector.BRISK('Threshold', 60), ...
    'O-BRISK', @() vicos.descriptor.BRISK(), ...
    'O-BRIEF64', @() vicos.descriptor.BRIEF(def_o_brief64{:}), ...
    'O-LATCH64', @() vicos.descriptor.LATCH(def_o_latch64{:}), ...
    'O-FREAK', @() vicos.descriptor.FREAK(def_o_freak{:}), ...
    'SO-FREAK', @() vicos.descriptor.FREAK(def_so_freak{:}, 'PatternScale', 22), ...
    'O-AG basic', @() vicos.descriptor.AlphaGamma(def_o_ag_basic{:}), ...
    'O-AG60', @() vicos.descriptor.AlphaGamma(def_o_ag_23x2_10{:}), ...
    'SO-AG60', @() vicos.descriptor.AlphaGamma(def_so_ag_23x2_10{:}, 'base_keypoint_size', 18.5) ...
    );

experiments(end+1) = define_experiment(...
    'kaze', ...
    'KAZE keypoints', ...
    @() vicos.keypoint_detector.KAZE(), ...
    'O-KAZE64', @() vicos.descriptor.KAZE('Extended', false), ...
    'O-BRIEF64', @() vicos.descriptor.BRIEF(def_o_brief64{:}), ...
    'O-LATCH64', @() vicos.descriptor.LATCH(def_o_latch64{:}), ...
    'O-FREAK', @() vicos.descriptor.FREAK(def_o_freak{:}), ...
    'SO-FREAK', @() vicos.descriptor.FREAK(def_so_freak{:}, 'PatternScale', 45), ...
    'O-AG basic', @() vicos.descriptor.AlphaGamma(def_o_ag_basic{:}), ...
    'O-AG60', @() vicos.descriptor.AlphaGamma(def_o_ag_23x2_10{:}), ...
    'SO-AG60', @() vicos.descriptor.AlphaGamma(def_so_ag_23x2_10{:}, 'base_keypoint_size', 6.5) ...
    );

% Run
affine_run_experiment('pairs', experiments, 'sequences', sequences, 'results_dir', results_dir, 'num_repetitions', num_repetitions, 'num_points', num_points, 'display_results', display_results);

%% Experiment 3: photometric
sequences = { 'trees', 'ubc', 'leuven' };
results_dir = fullfile(results_prefix, 'pairs-photometric');

% Define experiments
experiments = define_experiment();

experiments(end+1) = define_experiment(...
    'u-surf', ...
    'SURF keypoints (unoriented)', ...
    @() vicos.keypoint_detector.SURF('HessianThreshold', 400, 'NOctaves', 3, 'NOctaveLayers', 4, 'UpRight', true), ...
    'U-SURF', @() vicos.descriptor.SURF('UpRight', true), ...
    'U-BRIEF64', @() vicos.descriptor.BRIEF(def_u_brief64{:}), ...
    'U-LATCH64', @() vicos.descriptor.LATCH(def_u_latch64{:}), ...
    'U-FREAK', @() vicos.descriptor.FREAK(def_u_freak{:}), ...
    'SU-FREAK', @() vicos.descriptor.FREAK(def_su_freak{:}, 'PatternScale', 15), ...
    'U-AG basic', @() vicos.descriptor.AlphaGamma(def_u_ag_basic{:}), ...
    'U-AG60', @() vicos.descriptor.AlphaGamma(def_u_ag_23x2_10{:}), ...
    'SU-AG60', @() vicos.descriptor.AlphaGamma(def_su_ag_23x2_10{:}, 'base_keypoint_size', 18.5) ...
    );

experiments(end+1) = define_experiment(...
    'u-sift', ...
    'SIFT keypoints (unoriented)', ...
    @() vicos.keypoint_detector.SIFT('UpRight', true), ...
    'U-SIFT', @() vicos.descriptor.SIFT('UpRight', true), ...
    'U-BRIEF64', @() vicos.descriptor.BRIEF(def_u_brief64{:}), ...
    'U-LATCH64', @() vicos.descriptor.LATCH(def_u_latch64{:}), ...
    'U-FREAK', @() vicos.descriptor.FREAK(def_u_freak{:}), ...
    'SU-FREAK', @() vicos.descriptor.FREAK(def_su_freak{:}, 'PatternScale', 45), ...
    'U-AG basic', @() vicos.descriptor.AlphaGamma(def_u_ag_basic{:}), ...
    'U-AG60', @() vicos.descriptor.AlphaGamma(def_u_ag_23x2_10{:}), ...
    'SU-AG60', @() vicos.descriptor.AlphaGamma(def_su_ag_23x2_10{:}, 'base_keypoint_size', 3.25) ...
    );

experiments(end+1) = define_experiment(...
    'u-orb', ...
    'ORB keypoints (unoriented)', ...
    @() vicos.keypoint_detector.ORB('MaxFeatures', 3000, 'PatchSize', 18.5, 'UpRight', true), ... % Default patch size is around 30
    'U-ORB32', @() vicos.descriptor.ORB(), ...
    'U-BRIEF64', @() vicos.descriptor.BRIEF(def_u_brief64{:}), ...
    'U-LATCH64', @() vicos.descriptor.LATCH(def_u_latch64{:}), ...
    'U-FREAK', @() vicos.descriptor.FREAK(def_u_freak{:}), ...
    'SU-FREAK', @() vicos.descriptor.FREAK(def_su_freak{:}, 'PatternScale', 15), ...
    'U-AG basic', @() vicos.descriptor.AlphaGamma(def_u_ag_basic{:}), ...
    'U-AG60', @() vicos.descriptor.AlphaGamma(def_u_ag_23x2_10{:}), ...
    'SU-AG60', @() vicos.descriptor.AlphaGamma(def_su_ag_23x2_10{:}, 'base_keypoint_size', 18.5) ...
    );

experiments(end+1) = define_experiment(...
    'u-brisk', ...
    'BRISK keypoints (unoriented)', ...
    @() vicos.keypoint_detector.BRISK('Threshold', 60, 'UpRight', true), ...
    'U-BRISK', @() vicos.descriptor.BRISK(), ...
    'U-BRIEF64', @() vicos.descriptor.BRIEF(def_u_brief64{:}), ...
    'U-LATCH64', @() vicos.descriptor.LATCH(def_u_latch64{:}), ...
    'U-FREAK', @() vicos.descriptor.FREAK(def_u_freak{:}), ...
    'SU-FREAK', @() vicos.descriptor.FREAK(def_su_freak{:}, 'PatternScale', 22), ...
    'U-AG basic', @() vicos.descriptor.AlphaGamma(def_u_ag_basic{:}), ...
    'U-AG60', @() vicos.descriptor.AlphaGamma(def_u_ag_23x2_10{:}), ...
    'SU-AG60', @() vicos.descriptor.AlphaGamma(def_su_ag_23x2_10{:}, 'base_keypoint_size', 18.5) ...
    );

experiments(end+1) = define_experiment(...
    'u-kaze', ...
    'KAZE keypoints (unoriented)', ...
    @() vicos.keypoint_detector.KAZE('Upright', true), ...
    'U-KAZE64', @() vicos.descriptor.KAZE('Upright', true, 'Extended', false), ...
    'U-BRIEF64', @() vicos.descriptor.BRIEF(def_u_brief64{:}), ...
    'U-LATCH64', @() vicos.descriptor.LATCH(def_u_latch64{:}), ...
    'U-FREAK', @() vicos.descriptor.FREAK(def_u_freak{:}), ...
    'SU-FREAK', @() vicos.descriptor.FREAK(def_su_freak{:}, 'PatternScale', 45), ...
    'U-AG basic', @() vicos.descriptor.AlphaGamma(def_u_ag_basic{:}), ...
    'U-AG60', @() vicos.descriptor.AlphaGamma(def_u_ag_23x2_10{:}), ...
    'SU-AG60', @() vicos.descriptor.AlphaGamma(def_su_ag_23x2_10{:}, 'base_keypoint_size', 6.5) ...
    );

experiments(end+1) = define_experiment(...
    'surf', ...
    'SURF keypoints (oriented)', ...
    @() vicos.keypoint_detector.SURF('HessianThreshold', 400, 'NOctaves', 3, 'NOctaveLayers', 4), ...
    'O-SURF', @() vicos.descriptor.SURF(), ...
    'O-BRIEF64', @() vicos.descriptor.BRIEF(def_o_brief64{:}), ...
    'O-LATCH64', @() vicos.descriptor.LATCH(def_o_latch64{:}), ...
    'O-FREAK', @() vicos.descriptor.FREAK(def_o_freak{:}), ...
    'SO-FREAK', @() vicos.descriptor.FREAK(def_so_freak{:}, 'PatternScale', 15), ...
    'O-AG basic', @() vicos.descriptor.AlphaGamma(def_o_ag_basic{:}), ...
    'O-AG60', @() vicos.descriptor.AlphaGamma(def_o_ag_23x2_10{:}), ...
    'SO-AG60', @() vicos.descriptor.AlphaGamma(def_so_ag_23x2_10{:}, 'base_keypoint_size', 18.5) ...
    );

experiments(end+1) = define_experiment(...
    'sift', ...
    'SIFT keypoints (oriented)', ...
    @() vicos.keypoint_detector.SIFT(), ...
    'O-SIFT', @() vicos.descriptor.SIFT(), ...
    'O-BRIEF64', @() vicos.descriptor.BRIEF(def_o_brief64{:}), ...
    'O-LATCH64', @() vicos.descriptor.LATCH(def_o_latch64{:}), ...
    'O-FREAK', @() vicos.descriptor.FREAK(def_o_freak{:}), ...
    'SO-FREAK', @() vicos.descriptor.FREAK(def_so_freak{:}, 'PatternScale', 45), ...
    'O-AG basic', @() vicos.descriptor.AlphaGamma(def_o_ag_basic{:}), ...
    'O-AG60', @() vicos.descriptor.AlphaGamma(def_o_ag_23x2_10{:}), ...
    'SO-AG60', @() vicos.descriptor.AlphaGamma(def_so_ag_23x2_10{:}, 'base_keypoint_size', 3.25) ...
    );

experiments(end+1) = define_experiment(...
    'orb', ...
    'ORB keypoints', ...
    @() vicos.keypoint_detector.ORB('MaxFeatures', 3000, 'PatchSize', 18.5), ... % Default patch size is around 30
    'O-ORB32', @() vicos.descriptor.ORB(), ...
    'O-BRIEF64', @() vicos.descriptor.BRIEF(def_o_brief64{:}), ...
    'O-LATCH64', @() vicos.descriptor.LATCH(def_o_latch64{:}), ...
    'O-FREAK', @() vicos.descriptor.FREAK(def_o_freak{:}), ...
    'SO-FREAK', @() vicos.descriptor.FREAK(def_so_freak{:}, 'PatternScale', 15), ...
    'O-AG basic', @() vicos.descriptor.AlphaGamma(def_o_ag_basic{:}), ...
    'O-AG60', @() vicos.descriptor.AlphaGamma(def_o_ag_23x2_10{:}), ...
    'SO-AG60', @() vicos.descriptor.AlphaGamma(def_so_ag_23x2_10{:}, 'base_keypoint_size', 18.5) ...
    );

experiments(end+1) = define_experiment(...
    'brisk', ...
    'BRISK keypoints (oriented)', ...
    @() vicos.keypoint_detector.BRISK('Threshold', 60), ...
    'O-BRISK', @() vicos.descriptor.BRISK(), ...
    'O-BRIEF64', @() vicos.descriptor.BRIEF(def_o_brief64{:}), ...
    'O-LATCH64', @() vicos.descriptor.LATCH(def_o_latch64{:}), ...
    'O-FREAK', @() vicos.descriptor.FREAK(def_o_freak{:}), ...
    'SO-FREAK', @() vicos.descriptor.FREAK(def_so_freak{:}, 'PatternScale', 22), ...
    'O-AG basic', @() vicos.descriptor.AlphaGamma(def_o_ag_basic{:}), ...
    'O-AG60', @() vicos.descriptor.AlphaGamma(def_o_ag_23x2_10{:}), ...
    'SO-AG60', @() vicos.descriptor.AlphaGamma(def_so_ag_23x2_10{:}, 'base_keypoint_size', 18.5) ...
    );

experiments(end+1) = define_experiment(...
    'kaze', ...
    'KAZE keypoints', ...
    @() vicos.keypoint_detector.KAZE(), ...
    'O-KAZE64', @() vicos.descriptor.KAZE('Extended', false), ...
    'O-BRIEF64', @() vicos.descriptor.BRIEF(def_o_brief64{:}), ...
    'O-LATCH64', @() vicos.descriptor.LATCH(def_o_latch64{:}), ...
    'O-FREAK', @() vicos.descriptor.FREAK(def_o_freak{:}), ...
    'SO-FREAK', @() vicos.descriptor.FREAK(def_so_freak{:}, 'PatternScale', 45), ...
    'O-AG basic', @() vicos.descriptor.AlphaGamma(def_o_ag_basic{:}), ...
    'O-AG60', @() vicos.descriptor.AlphaGamma(def_o_ag_23x2_10{:}), ...
    'SO-AG60', @() vicos.descriptor.AlphaGamma(def_so_ag_23x2_10{:}, 'base_keypoint_size', 6.5) ...
    );

% Run
affine_run_experiment('pairs', experiments, 'sequences', sequences, 'results_dir', results_dir, 'num_repetitions', num_repetitions, 'num_points', num_points, 'display_results', display_results);

%% Experiment 4: rotation
sequences = 'graffiti';
results_dir = fullfile(results_prefix, 'rotation');

% Define experiments
experiments = define_experiment();

experiments(end+1) = define_experiment(...
    'u-surf', ...
    'SURF keypoints (unoriented)', ...
    @() vicos.keypoint_detector.SURF('HessianThreshold', 400, 'NOctaves', 3, 'NOctaveLayers', 4, 'UpRight', true), ...
    'U-SURF', @() vicos.descriptor.SURF('UpRight', true), ...
    'U-BRIEF64', @() vicos.descriptor.BRIEF(def_u_brief64{:}), ...
    'U-LATCH64', @() vicos.descriptor.LATCH(def_u_latch64{:}), ...
    'U-FREAK', @() vicos.descriptor.FREAK(def_u_freak{:}), ...
    'U-AG basic', @() vicos.descriptor.AlphaGamma(def_u_ag_basic{:}), ...
    'U-AG60', @() vicos.descriptor.AlphaGamma(def_u_ag_23x2_10{:}) ...
    );

experiments(end+1) = define_experiment(...
    'surf', ...
    'SURF keypoints (oriented)', ...
    @() vicos.keypoint_detector.SURF('HessianThreshold', 400, 'NOctaves', 3, 'NOctaveLayers', 4), ...
    'O-SURF', @() vicos.descriptor.SURF(), ...
    'O-BRIEF64', @() vicos.descriptor.BRIEF(def_o_brief64{:}), ...
    'O-LATCH64', @() vicos.descriptor.LATCH(def_o_latch64{:}), ...
    'O-FREAK', @() vicos.descriptor.FREAK(def_o_freak{:}), ...
    'O-AG basic', @() vicos.descriptor.AlphaGamma(def_o_ag_basic{:}), ...
    'O-AG60', @() vicos.descriptor.AlphaGamma(def_o_ag_23x2_10{:}) ...
    );

% Run
affine_run_experiment('rotation', experiments, 'sequences', sequences, 'results_dir', results_dir, 'num_repetitions', num_repetitions, 'num_points', num_points, 'display_results', display_results, 'values', 0:1:180);

%% Experiment 5: scale
sequences = 'graffiti';
results_dir = fullfile(results_prefix, 'scale');

% Define experiments
experiments = define_experiment();

experiments(end+1) = define_experiment(...
    'u-surf', ...
    'SURF keypoints (unoriented)', ...
    @() vicos.keypoint_detector.SURF('HessianThreshold', 400, 'NOctaves', 3, 'NOctaveLayers', 4, 'UpRight', true), ...
    'U-SURF', @() vicos.descriptor.SURF('UpRight', true), ...
    'U-BRIEF64', @() vicos.descriptor.BRIEF(def_u_brief64{:}), ...
    'U-LATCH64', @() vicos.descriptor.LATCH(def_u_latch64{:}), ...
    'U-FREAK', @() vicos.descriptor.FREAK(def_u_freak{:}), ...
    'SU-FREAK', @() vicos.descriptor.FREAK(def_su_freak{:}, 'PatternScale', 15), ...
    'U-AG60', @() vicos.descriptor.AlphaGamma(def_u_ag_23x2_10{:}), ...
    'SU-AG60', @() vicos.descriptor.AlphaGamma(def_su_ag_23x2_10{:}, 'base_keypoint_size', 18.5) ...
    );

experiments(end+1) = define_experiment(...
    'u-sift', ...
    'SIFT keypoints (unoriented)', ...
    @() vicos.keypoint_detector.SIFT('UpRight', true), ...
    'U-SIFT', @() vicos.descriptor.SIFT('UpRight', true), ...
    'U-BRIEF64', @() vicos.descriptor.BRIEF(def_u_brief64{:}), ...
    'U-LATCH64', @() vicos.descriptor.LATCH(def_u_latch64{:}), ...
    'U-FREAK', @() vicos.descriptor.FREAK(def_u_freak{:}), ...
    'SU-FREAK', @() vicos.descriptor.FREAK(def_su_freak{:}, 'PatternScale', 45), ...
    'U-AG60', @() vicos.descriptor.AlphaGamma(def_u_ag_23x2_10{:}), ...
    'SU-AG60', @() vicos.descriptor.AlphaGamma(def_su_ag_23x2_10{:}, 'base_keypoint_size', 3.25) ...
    );

experiments(end+1) = define_experiment(...
    'u-brisk', ...
    'BRISK keypoints (unoriented)', ...
    @() vicos.keypoint_detector.BRISK('Threshold', 60, 'UpRight', true), ...
    'U-BRISK', @() vicos.descriptor.BRISK(), ...
    'U-BRIEF64', @() vicos.descriptor.BRIEF(def_u_brief64{:}), ...
    'U-LATCH64', @() vicos.descriptor.LATCH(def_u_latch64{:}), ...
    'U-FREAK', @() vicos.descriptor.FREAK(def_u_freak{:}), ...
    'SU-FREAK', @() vicos.descriptor.FREAK(def_su_freak{:}, 'PatternScale', 22), ...
    'U-AG60', @() vicos.descriptor.AlphaGamma(def_u_ag_23x2_10{:}), ...
    'SU-AG60', @() vicos.descriptor.AlphaGamma(def_su_ag_23x2_10{:}, 'base_keypoint_size', 18.5) ...
    );

experiments(end+1) = define_experiment(...
    'u-kaze', ...
    'KAZE keypoints (unoriented)', ...
    @() vicos.keypoint_detector.KAZE('Upright', true), ...
    'U-KAZE64', @() vicos.descriptor.KAZE('Upright', true, 'Extended', false), ...
    'U-BRIEF64', @() vicos.descriptor.BRIEF(def_u_brief64{:}), ...
    'U-LATCH64', @() vicos.descriptor.LATCH(def_u_latch64{:}), ...
    'U-FREAK', @() vicos.descriptor.FREAK(def_u_freak{:}), ...
    'SU-FREAK', @() vicos.descriptor.FREAK(def_su_freak{:}, 'PatternScale', 45), ...
    'U-AG60', @() vicos.descriptor.AlphaGamma(def_u_ag_23x2_10{:}), ...
    'SU-AG60', @() vicos.descriptor.AlphaGamma(def_su_ag_23x2_10{:}, 'base_keypoint_size', 6.5) ...
    );


% Run
affine_run_experiment('scale', experiments, 'sequences', sequences, 'results_dir', results_dir, 'num_repetitions', num_repetitions, 'num_points', num_points, 'display_results', display_results, 'values', 0.5:0.01:1.5);


%% Experiment 6: shear
sequences = 'graffiti';
results_dir = fullfile(results_prefix, 'shear');

% Define experiments
experiments = define_experiment();

experiments(end+1) = define_experiment(...
    'u-surf', ...
    'SURF keypoints (unoriented)', ...
    @() vicos.keypoint_detector.SURF('HessianThreshold', 400, 'NOctaves', 3, 'NOctaveLayers', 4, 'UpRight', true), ...
    'U-SURF', @() vicos.descriptor.SURF('UpRight', true), ...
    'U-BRIEF64', @() vicos.descriptor.BRIEF(def_u_brief64{:}), ...
    'U-LATCH64', @() vicos.descriptor.LATCH(def_u_latch64{:}), ...
    'U-FREAK', @() vicos.descriptor.FREAK(def_u_freak{:}), ...
    'U-AG basic', @() vicos.descriptor.AlphaGamma(def_u_ag_basic{:}), ...
    'U-AG60', @() vicos.descriptor.AlphaGamma(def_u_ag_23x2_10{:}) ...
    );

experiments(end+1) = define_experiment(...
    'u-sift', ...
    'SIFT keypoints (unoriented)', ...
    @() vicos.keypoint_detector.SIFT('UpRight', true), ...
    'U-SIFT', @() vicos.descriptor.SIFT('UpRight', true), ...
    'U-BRIEF64', @() vicos.descriptor.BRIEF(def_u_brief64{:}), ...
    'U-LATCH64', @() vicos.descriptor.LATCH(def_u_latch64{:}), ...
    'U-FREAK', @() vicos.descriptor.FREAK(def_u_freak{:}), ...
    'U-AG basic', @() vicos.descriptor.AlphaGamma(def_u_ag_basic{:}), ...
    'U-AG60', @() vicos.descriptor.AlphaGamma(def_u_ag_23x2_10{:}) ...
    );

experiments(end+1) = define_experiment(...
    'u-brisk', ...
    'BRISK keypoints (unoriented)', ...
    @() vicos.keypoint_detector.BRISK('Threshold', 60, 'UpRight', true), ...
    'U-BRISK', @() vicos.descriptor.BRISK(), ...
    'U-BRIEF64', @() vicos.descriptor.BRIEF(def_u_brief64{:}), ...
    'U-LATCH64', @() vicos.descriptor.LATCH(def_u_latch64{:}), ...
    'U-FREAK', @() vicos.descriptor.FREAK(def_u_freak{:}), ...
    'U-AG basic', @() vicos.descriptor.AlphaGamma(def_u_ag_basic{:}), ...
    'U-AG60', @() vicos.descriptor.AlphaGamma(def_u_ag_23x2_10{:}) ...
    );

experiments(end+1) = define_experiment(...
    'u-kaze', ...
    'KAZE keypoints (unoriented)', ...
    @() vicos.keypoint_detector.KAZE('Upright', true), ...
    'U-KAZE64', @() vicos.descriptor.KAZE('Upright', true, 'Extended', false), ...
    'U-BRIEF64', @() vicos.descriptor.BRIEF(def_u_brief64{:}), ...
    'U-LATCH64', @() vicos.descriptor.LATCH(def_u_latch64{:}), ...
    'U-FREAK', @() vicos.descriptor.FREAK(def_u_freak{:}), ...
    'U-AG basic', @() vicos.descriptor.AlphaGamma(def_u_ag_basic{:}), ...
    'U-AG60', @() vicos.descriptor.AlphaGamma(def_u_ag_23x2_10{:}) ...
    );


% Run
affine_run_experiment('shear', experiments, 'sequences', sequences, 'results_dir', results_dir, 'num_repetitions', num_repetitions, 'num_points', num_points, 'display_results', display_results, 'values', -0.6:0.01:0.6);

%% Experiment 7: components
sequences = { 'bark', 'bikes', 'boat', 'graffiti', 'leuven', 'trees', 'ubc', 'wall', 'day_night' };
results_dir = fullfile(results_prefix, 'components');

% Define experiments
experiments = define_experiment();

experiments(end+1) = define_experiment(...
    'u-surf', ...
    'SURF keypoints (unoriented)', ...
    @() vicos.keypoint_detector.SURF('HessianThreshold', 400, 'NOctaves', 3, 'NOctaveLayers', 4, 'UpRight', true), ...
    'U-AG basic', @() vicos.descriptor.AlphaGamma(def_u_ag_basic{:}), ...
    'U-AG32-full', @() vicos.descriptor.AlphaGamma(def_u_ag_13x2_9{:}), ...
    'U-AG60-type1', @() vicos.descriptor.AlphaGamma(def_u_ag_23x2_10{:}, 'compute_base', true, 'compute_extended', false), ...
    'U-AG60-type2', @() vicos.descriptor.AlphaGamma(def_u_ag_23x2_10{:}, 'compute_base', false, 'compute_extended', true), ...
    'U-AG60-full', @() vicos.descriptor.AlphaGamma(def_u_ag_23x2_10{:}) ...
    );

% Run
affine_run_experiment('pairs', experiments, 'sequences', sequences, 'results_dir', results_dir, 'num_repetitions', num_repetitions, 'num_points', num_points, 'display_results', display_results);
