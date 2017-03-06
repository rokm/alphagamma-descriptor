function [ I1, I2, H12 ] = get_scaled_image (self, sequence, img, scale)
    % [ I1, I2, H12 ] = GET_ROTATED_IMAGE (self, sequence, img, scale)
    %
    % Loads an image from the affine dataset and scales it with the
    % specified scale factor.
    %
    % Input:
    %  - self:
    %  - sequence: sequence name
    %  - img: image to use
    %  - scale: scale factor
    %
    % Output:
    %  - I1: original image
    %  - I2: scaled image
    %  - H12: homography between both images
    %
    % NOTE: following the OpenCV keypoint convention, the returned
    % homography assumes a 0-based coordinate system (unlike the
    % Matlab's 1-based image coordinate system)
    
    % Load
    data_path = fullfile(self.dataset_path, sequence);
    
    I1 = imread( fullfile(data_path, sprintf('img%d.ppm', img)) );
    I2 = imresize(I1, scale, 'bilinear');
    
    % Construct the homography
    H12 = [ scale,      0, 0;
                0,  scale, 0;
                0,      0, 1 ];
end