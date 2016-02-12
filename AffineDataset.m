classdef AffineDataset
    % AFFINEDATASET - Oxford Affine Dataset adapter
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties (Access = private)
        dataset_path
        
        % Valid sequence names
        valid_sequences = { 'bark', 'bikes', 'boat', 'graffiti', 'leuven', 'trees', 'ubc', 'wall', 'day_night' };
    end
    
    methods
        function self = AffineDataset (varargin)
            % self = AFFINEDATASET (varargin)
            %
            % Creates AffineDataset adapter.
            %
            % Input: key/value pairs
            %  - dataset_path: path to the dataset
            %
            % Output:
            %  - @AffineDataset instance
            
            parser = inputParser();
            parser.addParameter('dataset_path', '/home/rok/Projects/jasna/datasets/affine', @ischar);
            parser.parse(varargin{:});
            
            % Dataset path
            self.dataset_path = parser.Results.dataset_path;
            assert(exist(self.dataset_path, 'dir') ~= 0, 'Non-existing dataset path');
        end
        
        function [ I1, I2, H12 ] = get_image_pair (self, sequence, i1, i2)
            % [ I1, I2, H12 ] = GET_IMAGE_PAIR (self, sequence, i1, i2)
            %
            % Loads an image pair from the affine dataset.
            %
            % Input:
            %  - self: @AffineDataset instance
            %  - sequence: sequence name
            %  - i1: first image (must be 1)
            %  - i2: second image (must be in range 2:6)
            %
            % Output:
            %  - I1: first image
            %  - I2: second image
            %  - H12: homography between both images

            % Validate parameters
            assert(ismember(sequence, self.valid_sequences), 'Invalid sequence name!');
            assert(i1 == 1, 'First image must be image #1!');
            assert(i2 >= 2 && i2 <= 6, 'Second image must be image #2..#6!');

            % Load
            data_path = fullfile(self.dataset_path, sequence);

            I1 = imread( fullfile(data_path, sprintf('img%d.ppm', i1)) );
            I2 = imread( fullfile(data_path, sprintf('img%d.ppm', i2)) );
            H12 = load( fullfile(data_path, sprintf('H%dto%dp', i1, i2)) );
        end
        
        function [ I1, I2, H12 ] = get_rotated_image (self, sequence, img, angle)
            % [ I1, I2, H12 ] = GET_ROTATED_IMAGE (self, sequence, img, angle)
            %
            % Loads an image from the affine dataset and rotates it for the
            % specified angle around the center.
            %
            % Input:
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

            % Validate parameters
            assert(ismember(sequence, self.valid_sequences), 'Invalid sequence name!');
            assert(img >= 1 && img <= 6, 'Image must be #1..#6!');

            % Load
            data_path = fullfile(self.dataset_path, sequence);

            I1 = imread( fullfile(data_path, sprintf('img%d.ppm', img)) );
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
        
        function [ I1, I2, H12 ] = get_scaled_image (self, sequence, img, scale)
            % [ I1, I2, H12 ] = GET_ROTATED_IMAGE (self, sequence, img, scale)
            %
            % Loads an image from the affine dataset and scales it with the
            % specified scale factor.
            %
            % Input:
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

            % Validate parameters
            assert(ismember(sequence, self.valid_sequences), 'Invalid sequence name!');
            assert(img >= 1 && img <= 6, 'Image must be #1..#6!');

            % Load
            data_path = fullfile(self.dataset_path, sequence);

            I1 = imread( fullfile(data_path, sprintf('img%d.ppm', img)) );
            I2 = imresize(I1, scale, 'bilinear');

            % Construct the homography
            H12 = [ scale,      0, 0; 
                        0,  scale, 0;
                        0,      0, 1 ];
        end
        
        function [ I1, I2, H12 ] = get_sheared_image (self, sequence, img, shear_x, shear_y)
            % [ I1, I2, H12 ] = GET_SHEARED_IMAGE (self, sequence, img, shear_x, shear_y)
            %
            % Loads an image from the affine dataset and applies shear in
            % x and y direction
            %
            % Input:
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
            
            % Validate parameters
            assert(ismember(sequence, self.valid_sequences), 'Invalid sequence name!');
            assert(img >= 1 && img <= 6, 'Image must be #1..#6!');

            % Load
            data_path = fullfile(self.dataset_path, sequence);

            I1 = imread( fullfile(data_path, sprintf('img%d.ppm', img)) );
            
            H12 = [ 1, shear_y, 0;
                    shear_x, 1, 0;
                    0, 0, 1 ];
                
            I2 = imwarp(I1, affine2d(H12), 'linear');
        end
    end
end