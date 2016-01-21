function recognition_rate = evaluate_descriptor_extractor (I1, I2, keypoints1, keypoints2, correspondences, descriptor_extractor)
    % recognition_rate = EVALUATE_DESCRIPTOR_EXTRACTOR (I1, I2, keypoints1, keypoints2, correspondences, descriptor_extractor)
    %
    % Evaluates the given descriptor extractor in terms of its recognition
    % rate. 
    % 
    % The definition of recognition rate follows the evaluation
    % methodology from (Calonder et al., 2011), which is based on nearest
    % neighbor correctness test. The recognition rate corresponds to the
    % fraction of keypoints/descriptors that are nearest neighbors in the
    % feature space, and are at the same time geometric correspondences.
    %
    % Here, we allow a keypoint to have multiple geometric correspondences,
    % in order to avoid unnecessary penalization of cases when detector
    % returns multiple keypoints at the same location, or in the very close
    % vicinity.
    %
    % This function assumes that the input keypoints are already
    % correspondence pairs, for example computed using
    % AFFINE_DETECT_CORRESPONDING_KEYPOINTS() function.
    %
    % Input:
    %  - I1: first image
    %  - I2: second image
    %  - keypoints1: keypoints from the first image (1xN structure array)
    %  - keypoints2: keypoints from the second image (1xN structure array)
    %  - correspondences: NxN matrix of logical values, in which the
    %    element (i,j) denotes whether i-th keypoint from the second set is
    %    considered to be geometric correspondence to j-th keypoint from
    %    the first set (i.e., columns correspond to keypoints from the
    %    first set, while rows correspond to keypoints from the second
    %    set). Because keypoints1 and keypoints2 are assumed to be two sets
    %    of corresponding points, each column and each row should have at
    %    least one element set to true (but, as multiple correspondences
    %    are permitted, more than one element can be set to true)
    %  - descriptor_extractor: descriptor extractor (instance of
    %    vicos.descriptor.Descriptor)
    %
    % Output:
    %  - recognition_rate: fraction of keypoints/descriptors that are 
    %    nearest neighbors in the feature space, and geometric
    %    correspondences at the same time
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    assert(numel(keypoints1) == numel(keypoints2), 'Number of elements in keypoints1 must match number of elements in keypoints2!');
    assert(all(size(correspondences) == numel(keypoints1)), 'Both dimensions of correspondences matrix must match the number of keypoints!');
    assert(isa(descriptor_extractor, 'vicos.descriptor.Descriptor'), 'descriptor_extractor must inherit from vicos.descriptor_extractor.Descriptor!'); 
    
    % Number of keypoint pairs that we are working with...
    num_keypoint_pairs = numel(keypoints1);

    %% Extract descriptors
    %t = tic();
    [ desc1, keypoints1b ] = descriptor_extractor.compute(I1, keypoints1);
    [ desc2, keypoints2b ] = descriptor_extractor.compute(I2, keypoints2);
    %fprintf('  >>> descriptor computation: %f seconds\n', toc(t));

    % Compute N2xN1 distance matrix (hence first desc2, then desc1)
    %t = tic();
    descriptor_distances = descriptor_extractor.compute_pairwise_distances(desc1, desc2);
    %fprintf('  >>> distance matrix computation: %f seconds\n', toc(t));

    %% Evaluate
    % Validate the matches; here, we need to be able to handle the cases when
    % the descriptor extractor dropped some points (may happen with OpenCV
    % implementations)... therefore, we compare the new point set with the
    % original one, and obtain list of point IDs with respect to original
    % point sets.
    ids1 = determine_point_ids(keypoints1, keypoints1b);
    ids2 = determine_point_ids(keypoints2, keypoints2b);
    
    num_correct_matches = 0;

    for i1 = 1:numel(keypoints1b),    
        % Find the nearest neighbour in descriptor space
        [ ~, i2 ] = min(descriptor_distances(:, i1));

        % Get the keypoints' "true" indices (the ones they had before going to
        % the descriptor extractor)
        idx1 = ids1(i1);
        idx2 = ids2(i2);

        % Validate the match
        %fprintf('%d <-> %d; true: %d\n', idx1, idx2, correspondences(idx2, idx1));
        if idx1 > 0 && idx2 > 0 && correspondences(idx2, idx1),
            num_correct_matches = num_correct_matches + 1;
        end
    end
   
    recognition_rate = num_correct_matches / num_keypoint_pairs;
end

function point_ids = determine_point_ids (original_keypoints, new_keypoints)
    % point_ids = DETERMINE_POINT_IDS (original_keypoints, new_keypoints)
    %
    % Compares two sets of keypoints - original ones, and ones that were
    % left after descriptor detection - and determines the IDs of the new
    % points, i.e., the corresponding linear indices in the original point
    % set.
    %
    % Input:
    %  - original_keypoints: 1xN array of original keypoints
    %  - new_keypoints: 1xM array of new keypoints. Some keypoints may be
    %    missing, while some may have been added.
    %
    % Output:
    %  - point_ids: 1xM array of point IDs, denoting the new points'
    %    linear indices in the original point set. If new points have been
    %    added, their ID will be set to 0
    
    point_ids = zeros(1, numel(new_keypoints));
    
    % Copy the fields from origianl point sets to vectors for a significant 
    % speed-up during comparisons....
    xy = vertcat(original_keypoints.pt);
    x = xy(:,1);
    y = xy(:,2);
    
    size = vertcat(original_keypoints.size);
    angle = vertcat(original_keypoints.angle);
    response = vertcat(original_keypoints.response);
    octave = vertcat(original_keypoints.octave);
    class_id = vertcat(original_keypoints.class_id);
    
    % Compare each new keypoint against the original ones
    for p = 1:numel(new_keypoints),
        kpt = new_keypoints(p);
        
        % Compare all fields; equivalent to 
        %  matches = arrayfun(@(x) isequal(x, new_keypoints(p)), original_keypoints)
        % but significantly faster...
        matches = kpt.pt(1) == x & kpt.pt(2) == y & kpt.size == size & kpt.angle == angle & kpt.response == response & kpt.octave == octave & kpt.class_id == class_id;
        
        % Determine the index of the match
        id = find(matches);
        if ~isempty(id),
            % Allow only one match
            assert(isscalar(id), 'Multiple point matches?!');
            point_ids(p) = id;
        end
    end
end