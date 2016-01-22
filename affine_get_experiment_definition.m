function experiment = affine_get_experiment_definition (experiment_name)
    % experiment = AFFINE_GET_EXPERIMENT_DEFINITION (experiment_name)
    %
    % Default experiment definition function.
    %
    % Input:
    %  - experiment_name: experiment name string
    %
    % Output:
    %  - experiment: experiment definition structure
    
    switch experiment_name,
        case 'surf-o',
            %% SURF keypoints, oriented descriptors
            experiment_title = 'SURF keypoints (oriented)';
            
            detector = vicos.keypoint_detector.SURF('HessianThreshold', 400, 'NOctaves', 3, 'NOctaveLayers', 4);
            
            descriptors = {};
            
            descriptors(end+1,:) = { 'SURF',  vicos.descriptor.SURF() };
            descriptors(end+1,:) = { 'O-BRIEF64', vicos.descriptor.BRIEF('Bytes', 64, 'UseOrientation', true) };
            descriptors(end+1,:) = { 'O-LATCH64', vicos.descriptor.LATCH('Bytes', 64, 'RotationInvariance', true) };

            descriptors(end+1,:) = { 'O-\alpha\gamma simple', vicos.descriptor.AlphaGamma('orientation', true, 'extended', false, 'sampling', 'simple', 'use_scale', false, 'base_sigma', sqrt(2)) };
            descriptors(end+1,:) = { 'O-\alpha\gamma C55x2', vicos.descriptor.AlphaGamma('orientation', true, 'extended', true, 'sampling', 'gaussian', 'use_scale', false) };
            descriptors(end+1,:) = { 'O-\alpha\gamma C23x2', vicos.descriptor.AlphaGamma('orientation', true, 'extended', true, 'sampling', 'gaussian', 'use_scale', false, 'num_rays', 23) };
        
        case 'surf-u',
            %% SURF keypoints, unoriented descriptors
            experiment_title = 'SURF keypoints (unoriented)';
            
            detector = vicos.keypoint_detector.SURF('HessianThreshold', 400, 'NOctaves', 3, 'NOctaveLayers', 4, 'UpRight', true);
            
            descriptors = {};
            
            descriptors(end+1,:) = { 'U-SURF',  vicos.descriptor.SURF('UpRight', true) };
            descriptors(end+1,:) = { 'U-BRIEF64', vicos.descriptor.BRIEF('Bytes', 64, 'UseOrientation', false) };
            descriptors(end+1,:) = { 'U-LATCH64', vicos.descriptor.LATCH('Bytes', 64, 'RotationInvariance', false) };

            descriptors(end+1,:) = { 'U-\alpha\gamma simple', vicos.descriptor.AlphaGamma('orientation', false, 'extended', false, 'sampling', 'simple', 'use_scale', false, 'base_sigma', sqrt(2)) };
            descriptors(end+1,:) = { 'U-\alpha\gamma C55x2', vicos.descriptor.AlphaGamma('orientation', false, 'extended', true, 'sampling', 'gaussian', 'use_scale', false) };
            descriptors(end+1,:) = { 'U-\alpha\gamma C23x2', vicos.descriptor.AlphaGamma('orientation', false, 'extended', true, 'sampling', 'gaussian', 'use_scale', false, 'num_rays', 23) };
        
        case 'sift-o',
            %% SIFT keypoints, oriented descriptors
            experiment_title = 'SIFT keypoints (oriented)';
            
            detector = vicos.keypoint_detector.SIFT();

            descriptors = {};
            
            descriptors(end+1,:) = { 'SIFT',  vicos.descriptor.SIFT() };
            descriptors(end+1,:) = { 'O-BRIEF64', vicos.descriptor.BRIEF('Bytes', 64, 'UseOrientation', true) };
            descriptors(end+1,:) = { 'O-LATCH64', vicos.descriptor.LATCH('Bytes', 64, 'RotationInvariance', true) };

            descriptors(end+1,:) = { 'O-\alpha\gamma simple', vicos.descriptor.AlphaGamma('orientation', true, 'extended', false, 'sampling', 'simple', 'use_scale', false, 'base_sigma', sqrt(2)) };
            descriptors(end+1,:) = { 'O-\alpha\gamma C55x2', vicos.descriptor.AlphaGamma('orientation', true, 'extended', true, 'sampling', 'gaussian', 'use_scale', false) };
            descriptors(end+1,:) = { 'O-\alpha\gamma C23x2', vicos.descriptor.AlphaGamma('orientation', true, 'extended', true, 'sampling', 'gaussian', 'use_scale', false, 'num_rays', 23) };
            
        case 'sift-u',
            %% SIFT keypoints, unoriented descriptors
            experiment_title = 'SIFT keypoints (unoriented)';

            detector = vicos.keypoint_detector.SIFT('UpRight', true);
            
            descriptors = {};
        
            descriptors(end+1,:) = { 'U-SIFT',  vicos.descriptor.SIFT() };
            descriptors(end+1,:) = { 'U-BRIEF64', vicos.descriptor.BRIEF('Bytes', 64, 'UseOrientation', false) };
            descriptors(end+1,:) = { 'U-LATCH64', vicos.descriptor.LATCH('Bytes', 64, 'RotationInvariance', false) };

            descriptors(end+1,:) = { 'U-\alpha\gamma simple', vicos.descriptor.AlphaGamma('orientation', false, 'extended', false, 'sampling', 'simple', 'use_scale', false, 'base_sigma', sqrt(2)) };
            descriptors(end+1,:) = { 'U-\alpha\gamma C55x2', vicos.descriptor.AlphaGamma('orientation', false, 'extended', true, 'sampling', 'gaussian', 'use_scale', false) };
            descriptors(end+1,:) = { 'U-\alpha\gamma C23x2', vicos.descriptor.AlphaGamma('orientation', false, 'extended', true, 'sampling', 'gaussian', 'use_scale', false, 'num_rays', 23) };

        case 'orb',
            %% ORB keypoints
            experiment_title = 'ORB keypoints';

            keypoint_detector = vicos.keypoint_detector.ORB('MaxFeatures', 2000);

            descriptors = {};
            
            descriptors(end+1,:) = { 'ORB-32',  vicos.descriptor.ORB('MaxFeatures', 2000) };
            descriptors(end+1,:) = { 'O-BRIEF64', vicos.descriptor.BRIEF('Bytes', 64, 'UseOrientation', true) };
            descriptors(end+1,:) = { 'O-LATCH64', vicos.descriptor.LATCH('Bytes', 64, 'RotationInvariance', true) };
            descriptors(end+1,:) = { 'U-BRIEF64', vicos.descriptor.BRIEF('Bytes', 64, 'UseOrientation', false) };
            descriptors(end+1,:) = { 'U-LATCH64', vicos.descriptor.LATCH('Bytes', 64, 'RotationInvariance', false) };

            descriptors(end+1,:) = { 'O-\alpha\gamma simple', vicos.descriptor.AlphaGamma('orientation', true, 'extended', false, 'sampling', 'simple', 'use_scale', false, 'base_sigma', sqrt(2)) };
            descriptors(end+1,:) = { 'O-\alpha\gamma C55x2', vicos.descriptor.AlphaGamma('orientation', true, 'extended', true, 'sampling', 'gaussian', 'use_scale', false) };
            descriptors(end+1,:) = { 'O-\alpha\gamma C23x2', vicos.descriptor.AlphaGamma('orientation', true, 'extended', true, 'sampling', 'gaussian', 'use_scale', false, 'num_rays', 23) };

            descriptors(end+1,:) = { 'U-\alpha\gamma simple', vicos.descriptor.AlphaGamma('orientation', false, 'extended', false, 'sampling', 'simple', 'use_scale', false, 'base_sigma', sqrt(2)) };
            descriptors(end+1,:) = { 'U-\alpha\gamma C55x2', vicos.descriptor.AlphaGamma('orientation', false, 'extended', true, 'sampling', 'gaussian', 'use_scale', false) };
            descriptors(end+1,:) = { 'U-\alpha\gamma C23x2', vicos.descriptor.AlphaGamma('orientation', false, 'extended', true, 'sampling', 'gaussian', 'use_scale', false, 'num_rays', 23) };

        case 'brisk',
        %% BRISK keypoints
            experiment_title = sprintf('%s - BRISK keypoints', sequence);
            
            detector = vicos.keypoint_detector.BRISK('Threshold', 60);

            descriptors = {};
            
            descriptors(end+1,:) = { 'BRISK',  vicos.descriptor.BRISK('Threshold', 60) };
            descriptors(end+1,:) = { 'O-BRIEF64', vicos.descriptor.BRIEF('Bytes', 64, 'UseOrientation', true) };
            descriptors(end+1,:) = { 'O-LATCH64', vicos.descriptor.LATCH('Bytes', 64, 'RotationInvariance', true) };
            descriptors(end+1,:) = { 'U-BRIEF64', vicos.descriptor.BRIEF('Bytes', 64, 'UseOrientation', false) };
            descriptors(end+1,:) = { 'U-LATCH64', vicos.descriptor.LATCH('Bytes', 64, 'RotationInvariance', false) };

            descriptors(end+1,:) = { 'O-\alpha\gamma simple', vicos.descriptor.AlphaGamma('orientation', true, 'extended', false, 'sampling', 'simple', 'use_scale', false, 'base_sigma', sqrt(2)) };
            descriptors(end+1,:) = { 'O-\alpha\gamma C55x2', vicos.descriptor.AlphaGamma('orientation', true, 'extended', true, 'sampling', 'gaussian', 'use_scale', false) };
            descriptors(end+1,:) = { 'O-\alpha\gamma C23x2', vicos.descriptor.AlphaGamma('orientation', true, 'extended', true, 'sampling', 'gaussian', 'use_scale', false, 'num_rays', 23) };

            descriptors(end+1,:) = { 'U-\alpha\gamma simple', vicos.descriptor.AlphaGamma('orientation', false, 'extended', false, 'sampling', 'simple', 'use_scale', false, 'base_sigma', sqrt(2)) };
            descriptors(end+1,:) = { 'U-\alpha\gamma C55x2', vicos.descriptor.AlphaGamma('orientation', false, 'extended', true, 'sampling', 'gaussian', 'use_scale', false) };
            descriptors(end+1,:) = { 'U-\alpha\gamma C23x2', vicos.descriptor.AlphaGamma('orientation', false, 'extended', true, 'sampling', 'gaussian', 'use_scale', false, 'num_rays', 23) };
        
        case 'harris',
            %% Harris keypoints
            experiment_title = 'Harris corners';
            
            detector = vicos.keypoint_detector.Harris('MaxFeatures', 4000); % Max number of corners

            descriptors = {};
            descriptors(end+1,:) = { 'U-BRIEF64', vicos.descriptor.BRIEF('Bytes', 64, 'UseOrientation', false) };
            descriptors(end+1,:) = { 'U-LATCH64', vicos.descriptor.LATCH('Bytes', 64, 'RotationInvariance', false) };

            descriptors(end+1,:) = { 'O-\alpha\gamma simple', vicos.descriptor.AlphaGamma('orientation', true, 'extended', false, 'sampling', 'simple', 'use_scale', false, 'base_sigma', sqrt(2)) };
            descriptors(end+1,:) = { 'O-\alpha\gamma C55x2', vicos.descriptor.AlphaGamma('orientation', true, 'extended', true, 'sampling', 'gaussian', 'use_scale', false) };
            descriptors(end+1,:) = { 'O-\alpha\gamma C23x2', vicos.descriptor.AlphaGamma('orientation', true, 'extended', true, 'sampling', 'gaussian', 'use_scale', false, 'num_rays', 23) };

            descriptors(end+1,:) = { 'U-\alpha\gamma simple', vicos.descriptor.AlphaGamma('orientation', false, 'extended', false, 'sampling', 'simple', 'use_scale', false, 'base_sigma', sqrt(2)) };
            descriptors(end+1,:) = { 'U-\alpha\gamma C55x2', vicos.descriptor.AlphaGamma('orientation', false, 'extended', true, 'sampling', 'gaussian', 'use_scale', false) };
            descriptors(end+1,:) = { 'U-\alpha\gamma C23x2', vicos.descriptor.AlphaGamma('orientation', false, 'extended', true, 'sampling', 'gaussian', 'use_scale', false, 'num_rays', 23) };
    end
    
    experiment.name = experiment_name;
    experiment.title = experiment_title;
    experiment.keypoint_detector = detector;
    experiment.descriptor_extractors = descriptors;
end