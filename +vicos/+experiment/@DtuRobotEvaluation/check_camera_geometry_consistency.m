function consistent = check_camera_geometry_consistency (self, camera1, camera2, pt1, pt2)
    % consistent = CHECK_CAMERA_GEOMETRY_CONSISTENCY (self, camera1, camera2, pt1, pt2)
    %
    % Checks if the pair of correspondences from two cameras is
    % consistent with geometry of the corresponding cameras. From
    % the given pair of 2-D image points, a 3-D point is
    % reconstructed, and back-projected to both cameras; the pair
    % is consistent if reprojection error is smaller than the
    % specified tolerance.
    %
    % This function is equivalent to IsPointCamGeoConsistent() from
    % DTU Robot Evaluation Code.
    %
    % Input:
    %  - self:
    %  - camera1: 3x4 projective matrix for first camera
    %  - camera2: 3x4 projective matrix for second camera
    %  - pt1: 1x2 vector with image coordinates in first image
    %  - pt2: 1x2 vector with image coordinates in second image
    %
    % Output:
    %  - consistent: a boolean flag indicating whether the pair is
    %    consistent with camera-pair geometry or not
    
    % Reconstruct the 3-D point
    pt3d = self.reconstruct_point_3d(camera1, camera2, pt1, pt2);
    
    % Back-project
    pt2d1 = camera1 * [ pt3d; 1 ];
    pt2d1 = pt2d1(1:2) / pt2d1(3);
    
    pt2d2 = camera2 * [ pt3d; 1 ];
    pt2d2 = pt2d2(1:2) / pt2d2(3);
    
    % Back-projection error
    err = norm(pt2d1 - pt1) + norm(pt2d2 - pt2);
    
    % Consistency
    consistent = err < self.backprojection_threshold;
end