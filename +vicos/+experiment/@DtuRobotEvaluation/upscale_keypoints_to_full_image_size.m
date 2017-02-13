function keypoints = upscale_keypoints_to_full_image_size (keypoints)
    % keypoints = UPSCALE_KEYPOINTS_TO_FULL_IMAGE_SIZE (keypoints)
    %
    % Upscale keypoints, obtained on half-sized images, to full image size.
    % This function adjusts both keypoint location and size by factor 2.
    % The location is also adjusted by half pixel to account for bilinear
    % interpolation of the images during downsizing.
    %
    % Input:
    %  - keypoints: array of OpenCV keypoint structures
    %
    % Output:
    %  - keypoints: array of OpenCV keypoint structures with adjusted 
    %    location and size; pt = 2*.pt + 0.5, and size = 2*size
    
    for i = 1:numel(keypoints)
        keypoints(i).pt = 2*keypoints(i).pt + 0.5;
        keypoints(i).size = 2*keypoints(i).size;
    end
end