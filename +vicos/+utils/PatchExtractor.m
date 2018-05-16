classdef PatchExtractor < handle
    % PATCHEXTRACTOR - Patch extractor utility
    %
    % This utility class allows extraction of scale-normalized (and
    % optionally orientation-normalized) patches from a set of keypoints.
    
    properties
        scale_factor
        target_size
        
        normalize_orientation
        replicate_border
        color_patches
    end
    
    methods
        function self = PatchExtractor (varargin)
            % self = PATCHEXTRACTOR (VARARGIN)
            %
            % Input: optional key/value pairs
            %  - scale_factor: scale factor to enlarge keypoint size
            %    (default: 5)
            %  - target_size: target width and height to which the sampled
            %    patch is resized (default: 64)
            %  - replicate_border: replicate border for patches that extend
            %    beyond valid image area (default: true). If disabled,
            %    such patches will not be extracted.
            %  - normalize_orientation: use keypoint-provided angle to
            %    normalize patch orientation (default: false)
            %  - color_patches: return 3-channel patches (default: false).
            %    If this option is enabled and input image is a grayscale
            %    one, it will be replicated across the three channels.
            %    Conversely, if this option is enabled and a color input
            %    image is provided, it will be converted to grayscale prior
            %    to patch extraction.
            %
            % Output:
            %  - self:
            
            parser = inputParser();
            parser.addParameter('scale_factor', 5, @isnumeric);
            parser.addParameter('target_size', 64, @isnumeric);
            parser.addParameter('replicate_border', true, @islogical);
            parser.addParameter('normalize_orientation', false, @islogical);
            parser.addParameter('color_patches', false, @islogical);
            parser.parse(varargin{:});
            
            self.scale_factor = parser.Results.scale_factor;
            self.target_size = parser.Results.target_size;
            self.replicate_border = parser.Results.replicate_border;
            self.color_patches = parser.Results.color_patches;
            self.normalize_orientation = parser.Results.normalize_orientation;
        end
        
        function [ patches, keypoints ] = extract_patches (self, I, keypoints)
            % [ PATCHES, KEYPOINTS ] = EXTRACT_PATCHES (self, I, keypoints)
            %
            % Extracts patches from provided image and keypoints. For each
            % provided keypoint, the patch is extracted from the
            % surrounding area corresponding to keypoint size times the
            % scale_factor, and rescaled to the target_size. The patches
            % are converted from/to grayscale according to color_patches
            % parameter as necessary.
            %
            % Input:
            %  - self:
            %  - I: input image (color or grayscale)
            %  - keypoints: 1xN array of keypoints
            %
            % Output:
            %  - patches: TSxTSxCxM tensor of extracted patches, with TS
            %    corresponding to the target_size, C being 1 (grayscale
            %    patches) or 3 (color patches), and M being the number of
            %    extracted patches (<= N).
            %  - keypoints: 1xM array of keypoints from which patches were
            %  extracted.
                        
            image_width = size(I, 2);
            image_height = size(I, 1);
            
            % Handle image channels and requested output channels
            if self.color_patches && size(I, 3) == 1
                I = repmat(I, 1, 1, 3); % Replicate grayscale image to three-channels
            elseif ~self.color_patches && size(I, 3) == 3
                I = rgb2gray(I);
            end
            
            % Allocate output
            patches = zeros(self.target_size, self.target_size, size(I, 3), numel(keypoints), 'like', I);
            
            valid_patch = false(numel(keypoints), 1);
            
            for i = 1:numel(keypoints)
                x = keypoints(i).pt(1) + 1; % OpenCV/C -> Matlab coordinates
                y = keypoints(i).pt(2) + 1;
                
                % If we normalize the patch orientation, we need to sample
                % a larger patch to rotate and then crop it again...
                rotation_enlargement = 1;
                if self.normalize_orientation
                    rotation_enlargement = sqrt(2);
                end
                
                % Round and scale
                x = round(x);
                y = round(y);
                radius = round(0.5*keypoints(i).size * self.scale_factor * rotation_enlargement);
                
                % Patch corners
                x1 = x - radius;
                x2 = x + radius;
                y1 = y - radius;
                y2 = y + radius;
                
                % Sanity check
                if x1 > image_width || x2 < 1 || y1 > image_height || y2 < 1
                    warning('Invalid patch!');
                    valid_patch(i) = false;
                    continue;
                end
                
                % If we are not replicating border, filter out patches that
                % would go past the image border
                if ~self.replicate_border && (x1 < 1 || x2 > image_width || y1 < 1 || y2 > image_height)
                    valid_patch(i) = false;
                    continue;
                end
                
                idx_x = x1:x2;
                idx_y = y1:y2;
                
                % Border replication
                if self.replicate_border
                    idx_x = max(1, min(image_width, idx_x));
                    idx_y = max(1, min(image_height, idx_y));
                end
                
                P = I(idx_y, idx_x, :);
                                
                assert(mod(size(P, 1), 2) == 1 && mod(size(P, 2), 2) == 1, 'Extracted patch is not of odd dimensions!'); % Sanity check
                
                % Orientation normalization
                if self.normalize_orientation
                    % Rotate image
                    P = imrotate(P, keypoints(i).angle, 'bilinear', 'crop');
                    
                    % Crop the original size
                    x = (size(P, 2) - 1)/2 + 1; % Make sure coordinates are in Matlab's 1-based coordinate system
                    y = (size(P, 1) - 1)/2 + 1;
                    radius = round(0.5*keypoints(i).size * self.scale_factor);
                    
                    x1 = x - radius;
                    x2 = x + radius;
                    y1 = y - radius;
                    y2 = y + radius;
                    
                    P = P(y1:y2, x1:x2, :);
                end    
                
                patches(:, :, :, i) = imresize(P, [ self.target_size, self.target_size ]);
                valid_patch(i) = true;
            end
            
            % Filter out invalid patches and keypoints
            patches(:, :, :, ~valid_patch) = [];
            keypoints(~valid_patch) = [];
        end
    end
end

