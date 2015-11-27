function fig = affine_visualize_correspondences(I1, I2, pts1, pts2, pts1p, pts2p, idx1, idx2)
    assert(numel(idx1) == numel(idx2), 'Mismatch in number of selected points!');
    
    num_points = numel(idx1);
    
    % Allocate colors
    colors = rand(3, num_points);
    
    %% New plot
    fig = figure('Name', 'Correspondences');
    
    % First image
    ha = tight_subplot(1, 2, 0, 0, 0);
    axes(ha(1));
    imshow(I1); hold on;
    scatter(pts1(1,idx1), pts1(2,idx1), [], colors', '+');
    scatter(pts2p(1,idx2), pts2p(2,idx2), [], colors', 'x');
    
    % Second image
    axes(ha(2));
    imshow(I2); hold on;
    scatter(pts2(1,idx2), pts2(2,idx2), [], colors', '+');
    scatter(pts1p(1,idx1), pts1p(2,idx1), [], colors', 'x');

    drawnow();
end
