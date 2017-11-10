function [ I1, I2, H12 ] = get_sheared_image (self, sequence, img, shear_x, shear_y)
    % [ I1, I2, H12 ] = GET_SHEARED_IMAGE (self, sequence, img, shear_x, shear_y)
    %
    % Loads an image from the affine dataset and applies shear in
    % x and y direction
    %
    % Input:
    %  - self:
    %  - sequence: sequence name
    %  - img: image to use
    %  - shear_x, shear_y: shear to apply
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
    I1 = imread(self.get_image_filename(sequence, img));
    
    A = [       1, shear_y, 0;
          shear_x,       1, 0;
                0,       0, 1 ];
    
    I2 = imwarp(I1, affine2d(A), 'linear');
    
    % Construct the homography
    % Move to the center
    T1 = [ 1, 0, -(size(I1,2) - 1)/2;
           0, 1, -(size(I1,1) - 1)/2;
           0, 0, 1 ];
    
    % Move back from the center
    T2 = [ 1, 0, (size(I2,2) - 1)/2;
           0, 1, (size(I2,1) - 1)/2;
           0, 0, 1 ];
    
    H12 = T2*A*T1;
end