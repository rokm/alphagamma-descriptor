function keypoints2 = project_keypoints (keypoints1, H)
    % keypoints2 = PROJECT_KEYPOINTS (keypoints, H)
    %
    % Projects keypoints using the provided homography. This function
    % projects both the keypoints' centers, as well as computes changes in
    % scales and orientations.
    %
    % Input:
    %  - keypoints1: keypoints to project
    %  - H: homography
    %
    % Output:
    %  - keypoints2: projected keypoints
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    keypoints2 = keypoints1;
    for p = 1:numel(keypoints1),
        keypoints2(p) = project_keypoint(keypoints1(p), H);
    end
end

function keypoint2 = project_keypoint (keypoint1, H)
    keypoint2 = keypoint1;

    %% Project center
    keypoint2.pt = project_points(keypoint1.pt', H)';
    
    %% Project the circle itself
    % Based on code from OpenCV...
    rad = keypoint1.size / 2;
    
    % Ellipse
    A = 1 / (rad*rad);
    B = 0;
    C = 1 / (rad*rad);
    
    % GetSecondMomentsMatrix()
    M = [ A, B; B, C ];
    
    Aff = linearize_homography_at(H, keypoint1.pt);
    %dstM = inv( Aff*inv(M)*Aff' );
    dstM = inv( Aff*M\Aff );
    
    % Resulting ellipse
    keypoint2.size = 2 * max( 1/sqrt(dstM(1, 1)), 1/sqrt(dstM(2, 2)) );
    
    %% Project the orientation
    if isfield(keypoint1, 'angle') && keypoint1.angle >= 0,
        vec = keypoint1.pt + [ cosd(keypoint1.angle), sind(keypoint1.angle) ];
        vec = [ vec, 1 ];
        vec = H*vec';
        vec = vec(1:2) / vec(3);
        
        y = vec(2) - keypoint2.pt(2); % Subtract the projected center
        x = vec(1) - keypoint2.pt(1);
        
        angle = atan2d(y, x);
        keypoint2.angle = mod(angle, 360);
    end
end

function Aff = linearize_homography_at (H, pt)
    tmp = H * [ pt'; 1];
    p1 = tmp(1);
    p2 = tmp(2);
    p3 = tmp(3);
    
    p3_2 = p3*p3;
    
    if p3,
        Aff = zeros(2,2);
        Aff(1,1) = H(1,1)/p3 - p1*H(3,1)/p3_2; % fxdx
        Aff(1,2) = H(1,2)/p3 - p1*H(3,2)/p3_2; % fxdy
        
        Aff(2,1) = H(2,1)/p3 - p2*H(3,1)/p3_2; % fydx
        Aff(2,2) = H(2,2)/p3 - p2*H(3,2)/p3_2; % fydy
    else
        Aff = Inf*ones(2,2);
    end
end

