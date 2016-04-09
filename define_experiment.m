function def = define_experiment (name, title, keypoint_detector_fcn, varargin)
    % def = DEFINE_EXPERIMENT (name, title, keypoint_detector_fcn, varargin)
    %
    % Experiment definition helper for AFFINE_RUN_EXPERIMENT();
    %
    
    if nargin == 0,
        % Empty structure for initialization
        def = repmat(struct('name', [], 'title', [], 'keypoint_detector_fcn', [], 'descriptors', []), 1, 0);
    else
        % Fully-fledged definition
        assert(mod(numel(varargin), 2) == 0, 'Descriptor definitions must be pairs of names and function handles!');
    
        def.name = name;
        def.title = title;
        def.keypoint_detector_fcn = keypoint_detector_fcn;
    
        for i = 1:numel(varargin)/2,
            idx = 2*(i-1) + 1;
            def.descriptors(i).name = varargin{idx};
            def.descriptors(i).create_fcn = varargin{idx+1};
        end
    end
end