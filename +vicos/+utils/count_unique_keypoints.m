function num = count_unique_keypoints (keypoints)
    % num = COUNT_UNIQUE_KEYPOINTS (keypoints)
    %
    % Returns the number of keypoints that are unique with respect to
    % center coordinates and size.
    %
    % Input:
    %  - keypoints: array of OpenCV keypoint structures
    %
    % Output:
    %  - num: number of unique keypoints w.r.t. position and size
    
    % Merge X, Y, and size into array...
    xys = [ vertcat(keypoints.pt), vertcat(keypoints.size) ];
    
    % ... and count unique rows
    tmp = unique(xys, 'rows');
    num = size(tmp, 1);
end
