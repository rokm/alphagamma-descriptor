function [ keypoints1, keypoints2, distances ] = detect_corresponding_keypoints (I1, I2, H12, keypoint_detector, varargin)
    % [ keypoints1, keypoints2, distances ] = DETECT_CORRESPONDING_KEYPOINTS (I1, I2, H12, keypoint_detector, varargin)
    % 
    % Finds a set of corresponding keypoints. Keypoints are detected in the
    % pair of input images, and geometric correspondences are established
    % based on the provided homography. A subset of correspondences are
    % randomly chosen, and returned for further processing.
    %
    % Input:
    %  - I1: first image
    %  - I2: second image
    %  - H: homography describing transformation from I1 to I2
    %  - keypoint_detector: keypoint detector
    %  - varargin: key/value pairs with optional parameters:
    %     - distance_threshold: keypoint distance threshold for
    %       establishing geometric correspondences (default: 2.5)
    %     - filter_border: image border size used when filtering the
    %       keypoints (default: 25 pixels)
    %     - num_points: number of correspondences to select (default: 500)
    %     - visualize: visualize the correspondences (default: false)
    %
    % Output:
    %  - keypoints1: selected keypoints in I1
    %  - keypoints2: selected keypoints in I2
    %  - distances: matrix of pair-wise distances between the selected
    %    keypoints I1 and back-projected keypoints from I2. Columns
    %    correspond to keypoints from I1, and rows correspond to
    %    back-projected keypoints from I2.
    %
    % Note: keypoints1 and keypoints2 are arrays of OpenCV keypoint
    % structures. The class_id field has been modified to contain the
    % sequential number of each keypoint; this should allow the
    % identification of keypoints that may be dropped during the descriptor
    % computation phase.
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    %% Gather optional arguments
    parser = inputParser();
    parser.addParameter('distance_threshold', 2.5, @isnumeric);
    parser.addParameter('filter_border', 25, @isnumeric);
    parser.addParameter('num_points', 500, @isnumeric);
    parser.addParameter('visualize', false, @islogical);
    parser.parse(varargin{:});
    
    distance_threshold = parser.Results.distance_threshold;
    filter_border = parser.Results.filter_border;
    num_points = parser.Results.num_points;
    visualize = parser.Results.visualize;

    %% Detect keypoints
    keypoints1 = keypoint_detector.detect(I1);
    keypoints2 = keypoint_detector.detect(I2);

    %% Image-border-based filtering
    % Project points in both direction, and filter out the ones that fall
    % outside the specified image borders
    pts1 = vertcat(keypoints1.pt)';
    pts2 = vertcat(keypoints2.pt)';

    pts1p = project_points(pts1, H12);
    pts2p = project_points(pts2, inv(H12));

    invalid_idx1 = pts1p(1,:) < filter_border | pts1p(1,:) >= (size(I2, 2) - filter_border) | pts1p(2,:) < filter_border | pts1p(2,:) >= (size(I2, 1) - filter_border);
    invalid_idx2 = pts2p(1,:) < filter_border | pts2p(1,:) >= (size(I1, 2) - filter_border) | pts2p(2,:) < filter_border | pts2p(2,:) >= (size(I1, 1) - filter_border);

    keypoints1(invalid_idx1) = [];
    keypoints2(invalid_idx2) = [];

    pts1(:,invalid_idx1) = [];
    pts2(:,invalid_idx2) = [];

    pts1p(:,invalid_idx1) = [];
    pts2p(:,invalid_idx2) = [];

    %% Compute distances (project points from 2nd image back into 1st)
    % The function below computes the matrix of pair-wise distances (N2xN1, as
    % we compare points from 1st image and the back-projected points from 2nd
    % image), as well as the matrix of greedy matches.
    %
    % The one-to-one matching will allow us to select the subset of points in 
    % both images. Note that when performing the actual evaluation, we will 
    % consider all possible correspondences between the selected points 
    % instead...
    [ distances, correspondences ] = compute_keypoint_distances(pts1, pts2p, distance_threshold);

    % The correspondences matrix contains non-zero entries that effectively 
    % denote the ranking of the match; so max value is the total number of 
    % correspondences
    num_correspondences = max(correspondences(:));

    % Select subset of correspondences
    num_points = min(num_points, num_correspondences);
    selected_idx = randperm(num_correspondences, num_points);

    % Find the indices of selected correspondences
    [ i2, i1 ] = find(ismember(correspondences, selected_idx));

    assert( all(sqrt( sum((pts1(:,i1) - pts2p(:,i2)).^2) ) < distance_threshold), 'Bug in the code!');

    %% Select the points
    keypoints1 = keypoints1(i1);
    keypoints2 = keypoints2(i2);

    pts1 = pts1(:,i1);
    pts2 = pts2(:,i2);

    pts1p = pts1p(:,i1);
    pts2p = pts2p(:,i2);

    distances = distances(i2,i1);

    % Augment keypoints with class IDs; this will allow us to identify any
    % keypoints that might be dropped during descriptor computation
    keypoints1 = augment_keypoints_with_id(keypoints1);
    keypoints2 = augment_keypoints_with_id(keypoints2);

    %% Display
    if visualize,
        colors = rand(3,num_points);

        figure('Name', '1st image');
        imshow(I1);
        hold on;
        scatter(pts1(1,:)', pts1(2,:)', [], colors');
        drawnow();

        figure('Name', '2nd image');
        imshow(I2);
        hold on;
        scatter(pts2(1,:)', pts2(2,:)', [], colors');
        drawnow();
    end
end