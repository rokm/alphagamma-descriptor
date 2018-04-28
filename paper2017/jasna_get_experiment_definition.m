function [ keypoint_detector, descriptor_extractor, alphagamma_float, alphagamma_short ] = jasna_get_experiment_definition (experiment_id)
    % [ keypoint_detector, native_descriptor, alphagamma_float, alphagamma_short ] = JASNA_GET_EXPERIMENT_DEFINITION (experiment_id)
    %
    % Common settings for keypoint detector/descriptor extractor
    % combinations used in the experiments.
    %
    % Input:
    %  - experiment_id: experiment ID; valid values: surf, sift, rootsift,
    %    brisk, orb, kaze, radial, lift
    %
    % Output:
    %  - keypoint_detector: factory function handle for keypoint detector
    %  - descriptor_extractor: factory function handle for native descriptor
    %    extractor (if applicable)
    %  - alphagamma_float: factory function handle for AG, parametrized for
    %    the selected keypoint detector
    %  - alphagamma_short: factory function handle for AGS, parametrized for
    %    the selected keypoint detector
    
    descriptor_extractor = [];
    alphagamma_float = [];
    alphagamma_short = [];
    
    switch lower(experiment_id)
        case 'surf'
            keypoint_detector = @() vicos.keypoint_detector.SURF();
            descriptor_extractor = @() vicos.descriptor.SURF();
            base_keypoint_size = 17.5;
        case 'sift'
            keypoint_detector = @() vicos.keypoint_detector.SIFT();
            descriptor_extractor = @() vicos.descriptor.SIFT();
            base_keypoint_size = 3.25;
        case 'rootsift'
            keypoint_detector = @() vicos.keypoint_detector.SIFT();
            descriptor_extractor = @() vicos.descriptor.RootSIFT();
            base_keypoint_size = 3.25;
        case 'brisk'
            keypoint_detector = @() vicos.keypoint_detector.BRISK();
            descriptor_extractor = @() vicos.descriptor.BRISK();
            base_keypoint_size = 18.5;
        case 'orb'
            keypoint_detector = @() vicos.keypoint_detector.ORB('MaxFeatures', 5000); % OpenCV-default is 500...
            descriptor_extractor = @() vicos.descriptor.ORB();
            base_keypoint_size = 18.5;
        case 'kaze'
            keypoint_detector = @() vicos.keypoint_detector.KAZE();
            descriptor_extractor = @() vicos.descriptor.KAZE('Extended', false);
            base_keypoint_size = 4.5;
        case 'radial'
            keypoint_detector = @() vicos.keypoint_detector.RADIAL();
            descriptor_extractor = [];
            base_keypoint_size = 4;
        case 'lift'
            keypoint_detector = @() vicos.keypoint_detector.LIFT();
            descriptor_extractor = @() vicos.descriptor.LIFT();
            base_keypoint_size = 3.25;
        % Extra definitions for VGG120 - the ScaleFactor parameter is as
        % per OpenCV documentation
        case 'surf+vgg120'
            keypoint_detector = @() vicos.keypoint_detector.SURF();
            descriptor_extractor = @() vicos.descriptor.VGG('ScaleFactor', 6.25);
            return;
        case 'sift+vgg120'
            keypoint_detector = @() vicos.keypoint_detector.SIFT();
            descriptor_extractor = @() vicos.descriptor.VGG('ScaleFactor', 6.75);
            return;
        case 'brisk+vgg120'
            keypoint_detector = @() vicos.keypoint_detector.BRISK();
            descriptor_extractor = @() vicos.descriptor.VGG('ScaleFactor', 5.00);
            return;
        case 'kaze+vgg120'
            keypoint_detector = @() vicos.keypoint_detector.KAZE();
            descriptor_extractor = @() vicos.descriptor.VGG('ScaleFactor', 6.25);
            return;
        case 'radial+vgg120'
            keypoint_detector = @() vicos.keypoint_detector.RADIAL();
            descriptor_extractor = @() vicos.descriptor.VGG('ScaleFactor', 5.0);
            return;
        case 'lift+vgg120'
            keypoint_detector = @() vicos.keypoint_detector.LIFT();
            descriptor_extractor = @() vicos.descriptor.VGG('ScaleFactor', 6.75);
            return;
        otherwise
            error('Invalid experiment id: "%s"', experiment_id);
    end
    
    % If a single-value base keypoint size is provided, duplicate it
    if isscalar(base_keypoint_size)
        base_keypoint_size(2) = base_keypoint_size;
    end
    
    alphagamma_float = @() vicos.descriptor.AlphaGamma('identifier', 'AG',  'non_binarized_descriptor', true,  'num_rays', 13, 'num_circles',  9,  'circle_step', sqrt(2)*1.104, 'base_keypoint_size', base_keypoint_size(1));
    alphagamma_short = @() vicos.descriptor.AlphaGamma('identifier', 'AGS', 'non_binarized_descriptor', false, 'num_rays', 23, 'num_circles', 10,  'circle_step', sqrt(2)*1.042, 'base_keypoint_size', base_keypoint_size(2));
end
