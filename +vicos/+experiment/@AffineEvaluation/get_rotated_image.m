function [ I1, I2, H12 ] = get_rotated_image (self, sequence, img, angle)
    % [ I1, I2, H12 ] = GET_ROTATED_IMAGE (self, sequence, img, angle)
    %
    % Loads an image from the affine dataset and rotates it for the
    % specified angle around the center.
    %
    % Input:
    %  - self:
    %  - sequence: sequence name
    %  - img: image to use
    %  - angle: angle to rotate (in degrees)
    %
    % Output:
    %  - I1: original image
    %  - I2: rotated image
    %  - H12: homography between both images
    %
    % NOTE: following the OpenCV keypoint convention, the returned
    % homography assumes a 0-based coordinate system (unlike the
    % Matlab's 1-based image coordinate system)
        
    % Load
    I1 = imread(self.get_image_filename(sequence, img));
    I2 = imrotate(I1, -angle, 'bilinear', 'loose'); % NOTE: imrotate rotates in counter-clockwise, while we expect rotation to be clockwise!
    
    % Construct the homography
    % Move to the center
    T1 = [ 1, 0, -(size(I1,2) - 1)/2;
           0, 1, -(size(I1,1) - 1)/2;
           0, 0, 1 ];
    
    % Rotate
    R = [ cosd(angle), -sind(angle), 0;
          sind(angle),  cosd(angle), 0
                    0,            0, 1 ];
    
    % Move back from the center
    T2 = [ 1, 0, (size(I2,2) - 1)/2;
           0, 1, (size(I2,1) - 1)/2;
           0, 0, 1 ];
    
    H12 = T2*R*T1;
end