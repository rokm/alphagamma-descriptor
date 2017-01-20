function [ idx, valid ] = get_consistent_correspondences (self, grid, camera1, camera2, ref_point, ref_scale, points, scales)
    % [ idx, valid ] = GET_CONSISTENT_CORRESPONDECNES (self, grid, camera1, camera2, ref_point, ref_scale, points, scales)
    %
    % Finds indices of keypoints from second image that are consistent with
    % reference keypoint from the reference image.
    %
    % Input:
    %  - self:
    %  - grid: quad-tree structure of structured-light 3-D point
    %    projections, obtained by GENERATE_STRUCTURED_LIGHT_GRID()
    %  - camera1: 3x4 projective matrix for first camera
    %  - camera2: 3x4 projective matrix for second camera
    %  - ref_point: 1x2 vector with image coordinates of reference keypoint
    %  - ref_scale: scale of reference keypoint
    %  - points: Nx2 vector of image coordinates of keypoints in second
    %    image
    %  - scales: Nx1 vector of scales corresponding to keypoints in second
    %    images
    %
    % Output:
    %  - idx: 1xC index list of valid correspondences
    %  - valid: a flag indicating whether the reference keypoint could be
    %    reconstructed from structured-light data
    
    % Reconstruct the reference keypoint
    [ mu, sigma, valid ] = self.lookup_point_3d(grid, ref_point');
    if ~valid
        idx = [];
        return;
    end
    
    % Create a bounding box with applied padding
    sigma = sigma + self.bbox_padding_3d;
    pts3d = mu*ones(1, 8) + [ sigma(1)*[ -1,  1, -1,  1, -1,  1, -1, 1 ];
                              sigma(2)*[ -1, -1,  1,  1, -1, -1,  1, 1 ];
                              sigma(3)*[ -1, -1, -1, -1,  1,  1,  1, 1 ] ]; % Eight bounding box corners
    
    % Project bounding box to reference image to obtain average depth
    pts2d = camera1 * [ pts3d; ones(1, size(pts3d, 2)) ];
    ref_depth = mean(pts2d(3,:)); % Average depth in reference image
                          
    % Project bounding box to second image
    pts2d = camera2 * [ pts3d; ones(1, size(pts3d, 2)) ];
    depth = mean(pts2d(3,:)); % Average depth
    pts2d = bsxfun(@rdivide, pts2d(1:2,:), pts2d(3,:));
    
    scale = ref_scale*ref_depth/depth;
    
    % Bounding box
    xmin = min(pts2d(1, :));
    xmax = max(pts2d(1, :));
    ymin = min(pts2d(2, :));
    ymax = max(pts2d(2, :));
    
    % Find points in second image that are within the projected bounding
    % box, and within the scale bounds
    valid_mask = points(:,1) > xmin & points(:,1) < xmax & points(:,2) > ymin & points(:,2) < ymax & scales > scale/self.scale_margin & scales < scale*self.scale_margin;
    valid_idx = find(valid_mask);
    
    % Check the camera-geometry consistency for valid points
    for i = 1:numel(valid_idx)
        idx = valid_idx(i);
        valid_mask(idx) = self.check_camera_geometry_consistency(camera1, camera2, ref_point', points(idx,:)') == 1;
    end
    
    idx = find(valid_mask);
end