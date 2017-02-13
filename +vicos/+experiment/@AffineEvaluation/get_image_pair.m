function [ I1, I2, H12 ] = get_image_pair (self, sequence, i1, i2)
    % [ I1, I2, H12 ] = GET_IMAGE_PAIR (self, sequence, i1, i2)
    %
    % Loads an image pair from the affine dataset.
    %
    % Input:
    %  - self:
    %  - sequence: sequence name
    %  - i1: first image (must be 1)
    %  - i2: second image (must be in range 2:6)
    %
    % Output:
    %  - I1: first image
    %  - I2: second image
    %  - H12: homography between both images
    
    % Load
    data_path = fullfile(self.dataset_path, sequence);
    
    I1 = imread( fullfile(data_path, sprintf('img%d.ppm', i1)) );
    I2 = imread( fullfile(data_path, sprintf('img%d.ppm', i2)) );
    H12 = load( fullfile(data_path, sprintf('H%dto%dp', i1, i2)) );
end
