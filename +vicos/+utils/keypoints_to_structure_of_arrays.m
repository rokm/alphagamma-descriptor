function soa = keypoints_to_structure_of_arrays (keypoints)
    % soa = KEYPOINTS_TO_STRUCTURE_OF_ARRAYS (keypoints)
    %
    % Converts input keypoint array-of-structures (as returned by OpenCV
    % keypoint detectors into a structure-of-arrays). 
    %
    % Input:
    %  - keypoints: array of OpenCV keypoint structures
    %
    % Output:
    %  - soa: keypoints' data organized in structure of array
    %
    % NOTE: while The Daily WTF may joke about 'arrject' anti-pattern, SOA 
    % has significantly lower storage footprint in Matlab, especially at
    % high numbers of keypoints, and is thus a much better choice for
    % our keypoint caching.
    
    % If input argument is a single structure, assume that it is already in
    % the SOA format (or is a single keypoint structure, which amounts to
    % the same thing).
    if numel(keypoints) == 1
        soa = keypoints;
        return;
    end
    
    % Convert AOS to SOA
    soa.pt = vertcat(keypoints.pt);
    soa.size = vertcat(keypoints.size);
    soa.angle = vertcat(keypoints.angle);
    soa.response = vertcat(keypoints.response);
    soa.octave = vertcat(keypoints.octave);
    soa.class_id = vertcat(keypoints.class_id);
end