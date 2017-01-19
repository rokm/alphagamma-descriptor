function grid = generate_structured_light_grid (self, image_set, reference_image)
    % grid = GENERATE_STRUCTURED_LIGHT_GRID (self, image_set, reference_image)
    %
    % Generates the projection of structured-light grid (i.e.,
    % ground truth points) and grids them into a two-level quad
    % tree for faster lookup.
    %
    % This function is equivalent to GenStrLightGrid_v2() from DTU
    % Robot Evaluation Code (except the rows and columns of the
    % quad tree correspond to dimensions of image).
    %
    % Input:
    %  - self:
    %  - image_set:
    %  - reference_image:
    %
    % Output:
    %  - grid: resulting lookup grid structure
    %     - pts: 5xN matrix of points (2D and 3D coordinates)
    %     - grid3d: indices
    
    % Image dimensions
    image_width = 1600;
    image_height = 1200;
    if self.half_size_images
        image_width = image_width / 2;
        image_height = image_height / 2;
    end
    
    % Load data file
    data_file = fullfile(self.dataset_path, 'CleanRecon_2009_11_16', sprintf('Clean_Reconstruction_%02d.mat', image_set));
    assert(exist(data_file, 'file') ~= 0, 'Structured-light data file "%s" does not exist!', data_file);
    
    data = load(data_file);
    
    % Gather 3-D points
    pts3d = [ data.pts3D_near(1:3,:), data.pts3D_far(1:3,:) ];
    
    % Project to reference image
    pts2d = self.cameras(:,:,reference_image) * [ pts3d; ones(1, size(pts3d, 2)) ];
    pts2d = bsxfun(@rdivide, pts2d(1:2,:), pts2d(3,:));
    
    % Merge points
    pts = [ pts2d; pts3d ];
    
    % Generate grid
    grid_rows = ceil(image_height / self.grid_cell_size);
    grid_cols = ceil(image_width / self.grid_cell_size);
    
    grid3d = cell(grid_rows, grid_cols);
    
    for i = 1:size(pts, 2)
        x = pts(1,i);
        y = pts(2,i);
        
        % Is projection inside the image?
        if x > 0 && x < image_width && y > 0 && y < image_height
            % Column and row
            c = ceil(x / self.grid_cell_size);
            r = ceil(y / self.grid_cell_size);
            
            % Append index
            grid3d{r,c}(end+1) = i;
        end
    end
    
    % Store results
    grid.pts = pts;
    grid.grid3d = grid3d;
end