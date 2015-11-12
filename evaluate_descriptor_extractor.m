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
    % DETECT_CORRESPONDING_KEYPOINTS() function.
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
    [ desc1, keypoints1b ] = descriptor_extractor.compute(I1, keypoints1);
    [ desc2, keypoints2b ] = descriptor_extractor.compute(I2, keypoints2);

    % Compute N2xN1 distance matrix (hence first desc2, then desc1)
    descriptor_distances = descriptor_extractor.compute_pairwise_distances(desc1, desc2);

    %% Evaluate
    % Validate the matches; here, we need to be able to handle the cases when
    % the descriptor extractor dropped some points (may happen with OpenCV
    % implementations), hence the round-about way with indexing via the
    % class_id fields...
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
        if correspondences(idx2, idx1),
            num_correct_matches = num_correct_matches + 1;
        end
    end
   
    recognition_rate = num_correct_matches / num_keypoint_pairs;
end