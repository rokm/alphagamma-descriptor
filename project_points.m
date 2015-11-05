function pts2 = project_points (pts, H)
    % pts2 = PROJECT_POINTS (pts, H)
    %
    % Projects a set of points using the provided homography.
    %
    % Input:
    %  - pts: 2xN array of points to project
    %  - H: homography matrix for projection
    %
    % Output:
    %  - pts2: 2xN array of projected points
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    pts2 = pts;
    pts2(3,:) = 1;
    pts2 = H * pts2;
    pts2 = bsxfun(@rdivide, pts2(1:2,:), pts2(3,:));
end