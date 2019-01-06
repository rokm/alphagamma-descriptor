function keypoints = keypoints_from_structure_of_arrays (soa)
    % keypoints = KEYPOINTS_FROM_STRUCTURE_OF_ARRAYS (soa)
    %
    % Converts input keypoint data, organized in structure-of-arrays
    % (output of KEYPOINTS_TO_STRUCTURE_OF_ARRAYS) back to the 
    % array-of-structures (as returned by OpenCV keypoint detectors). 
    %
    % Input:
    %  - soa: keypoint data in organized instructure-of-arrays 
    %
    % Output:
    %  - keypoints: array of OpenCV keypoint structures
    %
    %
    % NOTE: while The Daily WTF may joke about 'arrject' anti-pattern, SOA 
    % has significantly lower memory footprint in Matlab, especially at
    % high numbers of keypoints.
    
    % If input argument is array of structures, assume that it is already
    % in the AOS format, and leave it as it is
    if numel(soa) ~= 1
        keypoints = soa;
        return;
    end
    
    num_keypoints = size(soa.pt, 1);
    
    % Convert SOA to AOS
    keypoints = struct('pt', [ 0, 0 ], 'size', 0, 'angle', 0, 'response', 0, 'octave', 0, 'class_id', 0);
    keypoints = repmat(keypoints, 1, num_keypoints);
    
    for i = 1:num_keypoints
        keypoints(i).pt = soa.pt(i, :);
        keypoints(i).size = soa.size(i, :);
        keypoints(i).angle = soa.angle(i, :);
        keypoints(i).response = soa.response(i, :);
        keypoints(i).octave = soa.octave(i, :);
        keypoints(i).class_id = soa.class_id(i, :);
    end
end