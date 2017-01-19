function [ mu, sigma, valid ] = lookup_point_3d (self, grid, pt2d)
    % [ mu, sigma, valid ] = LOOKUP_POINT_3D (self, grid, pt2d)
    %
    % Looks up a 2-D point in the quad-tree of structured-light 3-D
    % point projections, which was previously obtained by a call
    % to GENERATE_STRUCTURED_LIGHT_GRID(). The 2-D point
    % coordinates must be from the image for which the quad-tree
    % was generated (i.e., the reference image).
    %
    % This function projects the point into grid, looks up 3D
    % coordinates of all neighbouring points, and computes the
    % mean and variance of 3-D coordinates for all points inside
    % the search radius (i.e., cell size).
    %
    % This function is equivalent to Get3DGridEst() from DTU
    % Robot Evaluation Code.
    %
    % Input:
    %  - self:
    %  - grid: quad-tree structure of structured-light 3-D point
    %    projections, obtained by GENERATE_STRUCTURED_LIGHT_GRID()
    %  - pt2d: 2x1 vector of 2-D point coordinates
    %
    % Output:
    %  - mu: 3x1 vector of mean 3-D coordinates
    %  - sigma: 3x1 vector of max deviations for 3-D coordinates
    %  - valid: validity flag (false if point falls outside the
    %    quad tree)
    
    grid_cell_size = self.grid_cell_size; % Cache for performance reasons
    grid_cells = grid.grid3d;
    grid_pts = grid.pts;
    
    % Grid column and row
    c = ceil(pt2d(1) / grid_cell_size);
    r = ceil(pt2d(2) / grid_cell_size);
    
    if r < 1 || r > size(grid_cells, 1) || c < 1 || c > size(grid_cells, 2)
        valid = false;
        mu = nan;
        sigma = nan;
        return;
    end
    
     % Gather 3-D coordinates of the neighbouring points
     pts3d = zeros(3, 0);
     
     for i = -1:1
         for j = -1:1
             r2 = r + j;
             c2 = c + i;
             
             % Validate cell coordinates
             if r2 < 1 || r2 > size(grid_cells, 1) || c2 < 1 || c2 > size(grid_cells, 2)
                 continue;
             end
             
             % For all structured-light points in the grid cell, chech if
             % their 2-D image coordinates are close enough to our 2-D
             % point; if so, we will add them to our list of points
             indices = grid.grid3d{r2, c2};
             valid_mask = sqrt(sum((bsxfun(@minus, grid_pts(1:2,indices), pt2d)).^2)) <= grid_cell_size;
             valid_indices = indices(valid_mask);
             pts3d = [ pts3d, grid_pts(3:5,valid_indices) ]; %#ok<AGROW>
        end
    end
    
    % No matches?
    if isempty(pts3d)
        valid = false;
        mu = nan;
        sigma = nan;
        return;
    end
    
    valid = true;
    
    % A single point ?
    if size(pts3d, 2) == 1
        mu = pts3d;
        sigma = zeros(3, 1);
        return;
    end
    
    mu = mean(pts3d, 2);
    sigma = max(abs(bsxfun(@minus, pts3d, mu)), [], 2);
end