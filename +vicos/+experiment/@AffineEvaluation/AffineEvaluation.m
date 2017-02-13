classdef AffineEvaluation < handle
    properties
        % Dataset path
        dataset_path
        
        % Back-projection error threshold for determining camera-geometry
        % consistency of a match (in pixels)
        backprojection_threshold
        
        % Distance ratio threshold for putative matches
        putative_match_ratio
        
        % Image border size (for keypoint filtering)
        filter_border
        
        % Global cache directory settings
        cache_dir
    end
    
    methods
        function self = AffineEvaluation (varargin)
            parser = inputParser();
            parser.addParameter('dataset_path', '', @ischar);
            parser.addParameter('half_size_images', true, @islogical);
            parser.addParameter('backprojection_threshold', 2.5, @isnumeric);
            parser.addParameter('putative_match_ratio', 0.8, @isnumeric);
            parser.addParameter('filter_border', 25, @isnumeric);
            parser.addParameter('cache_dir', '', @ischar);
            parser.parse(varargin{:});
            
            % Parameters
            self.filter_border = parser.Results.filter_border;
            self.backprojection_threshold = parser.Results.backprojection_threshold;
            self.putative_match_ratio = parser.Results.putative_match_ratio;
            
            % Global cache dir
            self.cache_dir = parser.Results.cache_dir;
            
            % Default dataset path
            self.dataset_path = parser.Results.dataset_path;
            if isempty(self.dataset_path)
                % Determine code root path
                code_root = fileparts(mfilename('fullpath'));
                code_root = fullfile(code_root, '..', '..', '..');
                self.dataset_path = fullfile(code_root, '..', 'datasets', 'affine');
            end
            
            assert(exist(self.dataset_path, 'dir') ~= 0, 'Invalid dataset root path "%s"!', self.dataset_path);
        end
        
        results = run_experiment (self, keypoint_detector, descriptor_extractor, sequence, varargin)
    end
    
    % Image pair retrieval
    methods
        [ I1, I2, H12 ] = get_image_pair (self, sequence, i1, i2)
        [ I1, I2, H12 ] = get_rotated_image (self, sequence, img, angle)
        [ I1, I2, H12 ] = get_scaled_image (self, sequence, img, scale)
        [ I1, I2, H12 ] = get_sheared_image (self, sequence, img, shear_x, shear_y)
    end
    
    methods
        function keypoints = detect_keypoints_in_image (self, I, keypoint_detector)
            %% FIXME: caching?
            image_size = size(I);
            keypoints = keypoint_detector.detect(I);

            % Filter keypoints at image border
            image_height = image_size(1);
            image_width = image_size(2);

            pts = vertcat(keypoints.pt) + 1; % C -> Matlab coordinates

            valid_mask = pts(:,1) >= (1+self.filter_border) & pts(:,1) <= (image_width-self.filter_border) & pts(:,2) >= (1+self.filter_border) & pts(:,2) <= (image_height-self.filter_border);
            keypoints(~valid_mask) = [];
            
            %% FIXME: caching
        end
        
        
        function [ descriptors, keypoints ] = extract_descriptors_from_keypoints (self, I, keypoint_detector, keypoints, descriptor_extractor)
            %% FIXME: caching?
            % Augment keypoints with sequential class IDs, so we can track
            % which points were dropped by descriptor extractor
            assert(all([ keypoints.class_id ] == -1), 'Keypoints do not have their class_id field set to -1! This may mean that the keypoint detector/descriptor extractor is using this field for its own purposes, which is not supported by this evaluation framework!');

            ids = num2cell(1:numel(keypoints));
            [ keypoints.class_id ] = deal(ids{:});

            % Extract descriptors
            t = tic();
            [ descriptors, keypoints ] = descriptor_extractor.compute(I, keypoints);
            time_descriptors = toc(t);
            
            %% FIXME: caching
        end        
        
        function [ match_idx, match_dist, correct_matches, putative_matches ] = evaluate_matches (self, H21, image_size, keypoint_detector, descriptor_extractor, ref_keypoints, ref_descriptors, test_keypoints, test_descriptors)
            % Compute descriptor distance matrix
            M = descriptor_extractor.compute_pairwise_distances(ref_descriptors, test_descriptors);

            % For each test keypoint (row in M), find the closest match
            Mm = M;
            [ min_dist1, min_idx1 ] = min(Mm, [], 2); % For each test keypoint, find the closest match

            % Find the next closest match (by masking the closest one)
            cidx = sub2ind(size(Mm), [ 1:numel(min_idx1) ]', min_idx1);
            Mm(cidx) = inf;
            [ min_dist2, min_idx2 ] = min(Mm, [], 2);

            % Store indices and distances
            match_idx = [ min_idx1, min_idx2 ];
            match_dist = [ min_dist1, min_dist2 ];

            % Determine geometric consistency of matches
            correct_matches = nan(numel(test_keypoints), 1);
            for j = 1:numel(test_keypoints)
                % Get the coordinates of the matched pair
                pt2 = test_keypoints(j).pt;
                pt1 = ref_keypoints(match_idx(j,1)).pt;
            
                % Evaluate geometric consistency; project test keypoint to
                % reference image
                pt2p = H21 * [ pt2, 1 ]';
                pt2p = pt2p(1:2)' / pt2p(3);
                
                if pt2p(1) >= 0 && pt2p(1) < image_size(2) && pt2p(2) >= 0 && pt2p(2) < image_size(1)
                    % Projection falls inside the reference image; check
                    % the distance
                    if norm(pt1 - pt2p) < self.backprojection_threshold
                        correct_matches(j) = 1;
                    else
                        correct_matches(j) = 0;
                    end
                else
                    % Projection falls outside the image
                    correct_matches(j) = -1;
                end
            end

            putative_matches = (min_dist1 ./ min_dist2) < self.putative_match_ratio;
        end
    end
end

