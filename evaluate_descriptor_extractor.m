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
    % A descriptor extractor may choose to discard some of the given
    % keypoints; some OpenCV-based extractors do that (e.g., if a keypoint
    % is too close to the image edge). We need to be able to detect this,
    % by comparing the input and output array of keypoints. However, a
    % descriptor extract may also choose to modify the angles of the
    % keypoints (for example, if it computes its own angles instead of
    % using the keypoint-detector-provided ones). Therefore, the only
    % really reliable way to do so is by assigning the keypoint indices to
    % their .class_id fields, and compare that. In order to do so, however,
    % we need to ensure that the descriptor extractor does not already use
    % the class_id for its own purpose - while it should not, at least
    % KAZE/AKAZE keypoint detector/descriptor extractor from OpenCV does
    % that. Therefore, the call to augment_keypoints_with_ids() checks if
    % the field is used, and raises an error - which means that the
    % descriptor implementation needs to be modified not to (ab)use the
    % class_id field.
    keypoints1 = augment_keypoints_with_id(keypoints1);
    keypoints2 = augment_keypoints_with_id(keypoints2);
    
    %t = tic();
    [ desc1, keypoints1b ] = descriptor_extractor.compute(I1, keypoints1);
    [ desc2, keypoints2b ] = descriptor_extractor.compute(I2, keypoints2);
    %fprintf('  >>> descriptor computation: %f seconds\n', toc(t));

    % Compute N2xN1 distance matrix (hence first desc2, then desc1)
    %t = tic();
    descriptor_distances = descriptor_extractor.compute_pairwise_distances(desc1, desc2);
    %fprintf('  >>> distance matrix computation: %f seconds\n', toc(t));

    %% Evaluate
    % Validate the matches
    num_correct_matches = 0;

    for i1 = 1:numel(keypoints1b),    
        % Find the nearest neighbour in descriptor space
        [ ~, i2 ] = min(descriptor_distances(:, i1));

        % Get the keypoints' "true" indices (the ones they had before going to
        % the descriptor extractor)
        idx1 = keypoints1b(i1).class_id;
        idx2 = keypoints2b(i2).class_id;

        % Validate the match
        %fprintf('%d <-> %d; true: %d\n', idx1, idx2, correspondences(idx2, idx1));
        if idx1 > 0 && idx2 > 0 && correspondences(idx2, idx1),
            num_correct_matches = num_correct_matches + 1;
        end
    end
   
    recognition_rate = num_correct_matches / num_keypoint_pairs;
end

function keypoints = augment_keypoints_with_id (keypoints)
    % keypoints = AUGMENT_KEYPOINTS_WITH_ID (keypoints)
    %
    % Augments keypoints with identifiers. Given the array of keypoint
    % structures, the class_id field of each keypoint is assigned its
    % consecutive number in the array. This is required to identify any
    % keypoints that a descriptor extractor discarded.
    %
    % NOTE: in order for this to work, the class_id must not be used by
    % descriptor extractor. Therefore, this function requires that class_id
    % of all keypoints is set to -1, and raises an error if it is not.
    %
    % Input:
    %  - keypoints: array of keypoints structures
    %
    % Output:
    %  - keypoints: array of keypoint structures with modified class_id
    %    field
    %
    % (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    % Catch incompatible keypoint detectors/descriptor extractors
    assert(all([ keypoints.class_id ] == -1), 'Keypoints do not have their class_id field set to -1! This may mean that the keypoint detector/descriptor extractor is using this field for its own purposes, which is not supported by this evaluation framework!');
    
    % Augment
    ids = num2cell(1:numel(keypoints));
    [ keypoints.class_id ] = deal(ids{:});
end