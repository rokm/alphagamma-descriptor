function correct = is_match_consistent (self, grid, camera1, camera2, pt1, pt2)
    % correct = IS_MATCH_CONSISTENT (self, grid, camera1, camera2, pt1, pt2)
    %
    % Evaluates consistency of a keypoint pair from two images.
    % The first image is expected to be the reference one, i.e.,
    % the one for which the quad tree of structured-light point
    % projections is given.
    %
    % This function is equivalent to IsMatchConsistent() from DTU
    % Robot Evaluation Code.
    %
    % Input:
    %  - self:
    %  - grid: quad-tree structure of structured-light 3-D point
    %  - camera1: 3x4 projective matrix for first camera
    %  - camera2: 3x4 projective matrix for second camera
    %  - pt1: 1x2 vector with image coordinates in first image
    %  - pt2: 1x2 vector with image coordinates in second image
    %
    % Output:
    %  - correct: a value indicating whether the match is correct
    %    (1), incorrect (-1), or could not be estimated because the
    %    point could not be matched to structured-light
    %    ground-truth points in the reference image (0)
    
    % Look up the point from the reference image in the
    % structured-light quad tree
    [ mu, sigma, valid ] = self.lookup_point_3d(grid, pt1);
    if ~valid
        correct = 0; % Cannot evaluate the correctness
        return;
    end
    
    % Create a bounding box with applied padding
    sigma = sigma + self.bbox_padding_3d;
    pts3d = mu*ones(1, 8) + [ sigma(1)*[ -1,  1, -1,  1, -1,  1, -1, 1 ];
                              sigma(2)*[ -1, -1,  1,  1, -1, -1,  1, 1 ];
                              sigma(3)*[ -1, -1, -1, -1,  1,  1,  1, 1 ] ]; % Eight bounding box corners
    
    % Project bounding box to second image
    pts2d = camera2 * [ pts3d; ones(1, size(pts3d, 2)) ];
    pts2d = bsxfun(@rdivide, pts2d(1:2,:), pts2d(3,:));
    
    % Bounding box
    xmin = min(pts2d(1, :));
    xmax = max(pts2d(1, :));
    ymin = min(pts2d(2, :));
    ymax = max(pts2d(2, :));
    
    if pt2(1) > xmin && pt2(1) < xmax && pt2(2) > ymin && pt2(2) < ymax
        % Validate camera-geometry consistency
        if self.check_camera_geometry_consistency(camera1, camera2, pt1, pt2)
            correct = 1;
        else
            correct = -1;
        end
    else
        correct = -1;
    end
end