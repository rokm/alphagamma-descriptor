function load_camera_calibration (self)
    % LOAD_CAMERA_CALIBRATION (self)
    %
    % Load camera calibration from dataset.
    
    % Camera calibration file
    calibration_file = fullfile(self.dataset_path, 'Calib_Results_11.mat');
    assert(exist(calibration_file, 'file') ~= 0, 'Camera calibration "%s" not found!', calibration_file);
    
    % Load
    tmp = load(calibration_file);
    
    % Pre-allocate camera matrices
    num_cameras = 119;
    self.cameras = zeros(3, 4, num_cameras);
    
    % Scale matrix
    if self.half_size_images
        S = [ 0.5,   0, 0;
            0, 0.5, 0;
            0,   0, 1 ];
    else
        S = eye(3);
    end
    
    % Load cameras
    K = [ tmp.fc(1),         0, tmp.cc(1);
        0, tmp.fc(2), tmp.cc(2);
        0,         0,         1 ];
    
    for i = 1:num_cameras
        R = tmp.(sprintf('Rc_%d', i));
        T = tmp.(sprintf('Tc_%d', i));
        
        self.cameras(:,:,i) = S * K * [ R, T ];
    end
end