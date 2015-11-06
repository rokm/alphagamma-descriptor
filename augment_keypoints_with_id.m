function keypoints = augment_keypoints_with_id (keypoints)
    % keypoints = AUGMENT_KEYPOINTS_WITH_ID (keypoints)
    %
    % Augments keypoints with identifiers. Given the array of keypoint
    % structures, the class_id field of each keypoint is assigned its
    % consecutive number in the array. This might be useful, for example,
    % to identify the points that are dropped during descriptor computation
    % by OpenCV's descriptor classes.
    %
    % Input:
    %  - keypoints: array of keypoints structures
    %
    % Output:
    %  - keypoints: array of keypoint structures with modified class_id
    %    field
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    ids = num2cell(1:numel(keypoints));
    [ keypoints.class_id ] = deal(ids{:});
end