function [ result, num_keypoints1, num_keypoints2, num_correspondences ] = affine_detect_corresponding_keypoints (I1, I2, H12, keypoint_detector, varargin)
    % [ result, num_keypoints1, num_keypoints2, num_correspondences ] = AFFINE_DETECT_CORRESPONDING_KEYPOINTS (I1, I2, H12, keypoint_detector, varargin)
    % 
    % Finds a set of corresponding keypoints. Keypoints are detected in the
    % pair of input images, and geometric correspondences are established
    % based on the provided homography. Alternatively, keypoints are
    % detected in the first image, and directly projected into the second
    % image using the provided homography. One or more subsets of 
    % correspondences are randomly chosen, and returned for further 
    % processing.
    %
    % Input:
    %  - I1: first image
    %  - I2: second image
    %  - H: homography describing transformation from I1 to I2
    %  - keypoint_detector: keypoint detector (instance of
    %    vicos.keypoint_detector.KeypointDetector)
    %  - varargin: key/value pairs with optional parameters:
    %     - distance_threshold: keypoint distance threshold for
    %       establishing geometric correspondences (default: 2.5)
    %     - filter_border: image border size used when filtering the
    %       keypoints (default: 25 pixels)
    %     - num_points: number of correspondences to select (default: 1000)
    %     - num_sets: number of randomly-selected correspondence subsets
    %       (default: 1). Useful for multiple repetitions of the experiment
    %       (because the keypoint pairs that we sample from will not change
    %       between repetitions).
    %     - visualize: visualize the correspondences (default: false)
    %
    % Output:
    %  - result: a structure or array of structures (depending on the
    %    num_sets parameter), with the following fields
    %     - keypoints1: selected keypoints in I1
    %     - keypoints2: selected keypoints in I2
    %     - distances: matrix of pair-wise distances between the selected
    %       keypoints I1 and back-projected keypoints from I2. Columns
    %       correspond to keypoints from I1, and rows correspond to
    %       back-projected keypoints from I2.
    %  - num_keypoints1: number of keypoints detected in I1
    %  - num_keypoints2: number of keypoints detected in I2
    %  - num_correspondences: number of established geometric
    %    correspondences between the two sets of keypoints
    %
    % Note: keypoints1 and keypoints2 are arrays of OpenCV keypoint
    % structures.
    %
    % Note: if the number of established correspondences is smaller than 
    % the number requested via num_points parameter, then only a single set
    % is returned, regardless of the num_sets parameter, because all sets
    % would be the same.
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    assert(isa(keypoint_detector, 'vicos.keypoint_detector.KeypointDetector'), 'keypoint_detector must inherit from vicos.keypoint_detector.KeypointDetector!'); 
    
    %% Gather optional arguments
    parser = inputParser();
    parser.addParameter('distance_threshold', 2.5, @isnumeric);
    parser.addParameter('filter_border', 25, @isnumeric);
    parser.addParameter('num_points', 1000, @isnumeric);
    parser.addParameter('num_sets', 1, @isnumeric);
    parser.addParameter('visualize', false, @islogical);
    parser.parse(varargin{:});
    
    distance_threshold = parser.Results.distance_threshold;
    filter_border = parser.Results.filter_border;
    num_points = parser.Results.num_points;
    num_sets = parser.Results.num_sets;
    visualize = parser.Results.visualize;

    %% Detect keypoints in first image
    keypoints1 = keypoint_detector.detect(I1);
    keypoints1 = filter_duplicated_keypoints(keypoints1);
    
    %% Obtain keypoints in second image
    keypoints2 = keypoint_detector.detect(I2);
    keypoints2 = filter_duplicated_keypoints(keypoints2);
    
    %% Image-border-based filtering
    % Project points in both direction, and filter out the ones that fall
    % outside the specified image borders
    pts1 = vertcat(keypoints1.pt)';
    pts2 = vertcat(keypoints2.pt)';

    pts1p = project_points(pts1, H12);
    pts2p = project_points(pts2, inv(H12));

    invalid_idx1 = find_invalid_points(pts1, I1, filter_border) | find_invalid_points(pts1p, I2, filter_border);
    invalid_idx2 = find_invalid_points(pts2, I2, filter_border) | find_invalid_points(pts2p, I1, filter_border);
    
    % Remove
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

    num_keypoints1 = size(pts1, 2);
    num_keypoints2 = size(pts2, 2);
    fprintf(' > computing distances: %d x %d\n', num_keypoints1, num_keypoints2);

    % Compute the distance matrix (colums correspond to poits in pts1,
    % while rows correspond to points in pts2p). Correspondences is a Cx2
    % vector, where first column represents indices in pts1, and second
    % column represents corresponding indices in pts2p).
    [ distances, correspondences ] = compute_keypoint_distances(pts1', pts2p', distance_threshold);
    
    num_correspondences = size(correspondences, 1);

    fprintf(' > found %d correspondences!\n', num_correspondences);
    
    %% Select subset(s) of correspondences
    num_points = min(num_points, num_correspondences);
    
    % If we found less correspondences than originally requested, do not
    % bother with creation of multiple sets, as they will all be the
    % same...
    if num_points == num_correspondences,
        num_sets = 1;
    end
    
    for r = num_sets:-1:1,
        % Select random subset
        selected_idx = randperm(num_correspondences, num_points);

        % Find the indices of selected correspondences
        i1 = correspondences(selected_idx, 1);
        i2 = correspondences(selected_idx, 2);
        
        assert( all(sqrt( sum((pts1(:,i1) - pts2p(:,i2)).^2) ) <= distance_threshold), 'Sanity check failed!');

        %% Select the points
        result(r).keypoints1 = keypoints1(i1);
        result(r).keypoints2 = keypoints2(i2);

        result(r).distances = distances(i2,i1);

        %% Display
        if visualize,
            affine_visualize_correspondences(I1, I2, pts1, pts2, pts1p, pts2p, i1, i2);
        end
    end
end

function [ distances, correspondences ] = compute_keypoint_distances (pts1, pts2, distance_threshold)
    % [ distances, correspondences ] = COMPUTE_KEYPOINT_DISTANCES (pts1, pts2p, distance_threshold)
    %
    % Computes pairwise distance matrix between two sets of keypoints'
    % centers, and finds an optimal assignment between the two, given the
    % maximum allowable distance.
    %
    % Input:
    %  - pts1: Mx2 vector of points' centers
    %  - pts2: Nx2 vector of points' centers
    %  - distance_threshold: Euclidean distance threshold for the
    %    assignment
    %
    % Output:
    %  - distances: NxM distance matrix
    %  - correspondences: Cx2 vector of correspondence indices (first and
    %    second column correspond to indices in the first and second point
    %    set, respectively). 
    %
    % Note: according to distance matrices, there may actually be more
    % allowable correspondences than the ones given in the output
    % correspondences matrix; the latter is useful primarily when one
    % wishes to sample from the set of detected correspondences.
   
    % Compute distance matrix; NxM, i.e., columns correspond to points in 
    % pts1, and rows correspond to points in pts2.
    distances = distance_matrix(pts2, pts1);
    
    % Apply distance threshold constraint.
    distances(distances>distance_threshold) = Inf;
    
    % Find assignment
    if nargout > 1,
        assignment = lapjv(distances);

        % The meaning of resulting assignment vector depends on which
        % dimension of the distance matrix is larger...
        if size(distances, 1) >= size(distances, 2),
            idx1 = assignment;
            idx2 = 1:size(distances, 2);
        else
            idx1 = 1:size(distances, 1);
            idx2 = assignment;
        end
        
        % LAPJV assigns the invalid (Inf) entries as well, hence the
        % isfinite check in the resulting pairs
        linear_idx = sub2ind(size(distances), idx1, idx2);
        valid_mask = isfinite(distances(linear_idx)); % 

        % The meaning of 'idx1' and 'idx2' is w.r.t. to dimensions of the
        % distance matrix; so their meaning w.r.t. point sets is actually
        % inverted!
        correspondences = [ idx2(valid_mask)', idx1(valid_mask)' ];
    end
end

function D = distance_matrix (X, Y)
    % D = DISTANCE_MATRIX (X, Y)
    %
    % Computes a matrix of pair-wise Euclidean distances between two sets
    % of points, X and Y.
    %
    % Input:
    %  - X: MxD vector of points
    %  - Y: NxD vector of points
    %
    % Output:
    %  - D: MxN distance matrix
    
    Yt = Y';
    XX = sum(X .* X, 2);
    YY = sum(Yt .* Yt, 1);
    D = bsxfun(@plus, XX, YY) - 2*X*Yt;
    D = sqrt(D);
end

function invalid_idx = find_invalid_points (pts, I, filter_border)
    % invalid_idx = FIND_INVALID_POINTS (pts, I, filter_border)
    %
    % Returns indices of points whose coordinates fall too close to image
    % borders.
   
    % Check all four borders
    invalid_idx = pts(1,:) < filter_border | pts(1,:) >= (size(I, 2) - filter_border) | pts(2,:) < filter_border | pts(2,:) >= (size(I, 1) - filter_border);
end

function keypoints = filter_duplicated_keypoints (keypoints)
    % keypoints = FILTER_DUPLICATED_KEYPOINTS (keypoints)
    %
    % Removes duplicated keypoints
    
    % Copy the fields from origianl point sets to vectors for a significant 
    % speed-up during comparisons....
    xy = vertcat(keypoints.pt);
    x = xy(:,1);
    y = xy(:,2);
    
    size = vertcat(keypoints.size);
    angle = vertcat(keypoints.angle);
    response = vertcat(keypoints.response);
    octave = vertcat(keypoints.octave);
    class_id = vertcat(keypoints.class_id);
    
    p = 1;
    while true,
        kpt = keypoints(p);
        
        % Compare all fields; equivalent to 
        %  matches = arrayfun(@(x) isequal(x, keypoints(p)), keypoints)
        % but significantly faster...
        matches = kpt.pt(1) == x & kpt.pt(2) == y & kpt.size == size & kpt.angle == angle & kpt.response == response & kpt.octave == octave & kpt.class_id == class_id;
        idx = find(matches);
        
        if numel(matches) > 1,
            idx = idx(2:end);
        
            keypoints(idx) = [];
            
            x(idx) = [];
            y(idx) = [];
            size(idx) = [];
            angle(idx) = [];
            response(idx) = [];
            octave(idx) = [];
            class_id(idx) = [];
        end
        
        p = p + 1;
        if p >= numel(keypoints),
            break;
        end
    end
end
