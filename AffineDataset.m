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
            assert(i1 == 1, 'First image must be image #1!');
            assert(i2 >= 2 && i2 <= 6, 'Second image must be image #2..#6!');
            assert(ismember(sequence, self.valid_sequences), 'Invalid sequence name!');

            % Load
            data_path = fullfile(self.dataset_path, sequence);

            I1 = imread( fullfile(data_path, sprintf('img%d.ppm', i1)) );
            I2 = imread( fullfile(data_path, sprintf('img%d.ppm', i2)) );
            H12 = load( fullfile(data_path, sprintf('H%dto%dp', i1, i2)) );
        end
        
        function [ I1, I2, H12 ] = get_rotated_image (self, sequence, i, angle)
            % [ I1, I2, H12 ] = GET_ROTATED_IMAGE (self, sequence, i1, angle)
            %
            % Loads an image from the affine dataset and rotates it for the
            % specified angle.
            %
            % Input:
            %  - sequence: sequence name
            %  - i: image to use
            %  - angle: angle to rotate (in degrees)
            %
            % Output:
            %  - I1: original image
            %  - I2: rotated image
            %  - H12: homography between both images

            % Validate parameters
            assert(i >= 1 && i <= 6, 'Second image must be image #1..#6!');
            assert(ismember(sequence, self.valid_sequences), 'Invalid sequence name!');

            % Load
            data_path = fullfile(self.dataset_path, sequence);

            I1 = imread( fullfile(data_path, sprintf('img%d.ppm', i)) );
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
    end
    
    methods (Static)
        function [ distances, correspondences ] = 
    end
    
end