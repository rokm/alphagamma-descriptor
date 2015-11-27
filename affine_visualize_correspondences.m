function fig = affine_visualize_correspondences(I1, I2, pts1, pts2, pts1p, pts2p, i1, i2)
    assert(numel(i1) == numel(i2), 'Mismatch in number of selected points!');
    
    num_points = numel(i1);
    
    % Allocate colors
    colors = rand(3, num_points);

    % Select points
    selected_pts1 = pts1(:, i1);
    selected_pts2 = pts2(:, i2);
    
    %% New plot
    fig = figure('Name', 'Correspondences');
    
    % First image
    ha = tight_subplot(1, 2, 0, 0, 0);
    axes(ha(1));
    imshow(I1);
    scatter(selected_pts1(1,:), selected_pts1(2,:), [], colors');
    
    % Second image
    axes(ha(2));
    imshow(I2);
    scatter(selected_pts2(1,:), selected_pts2(2,:), [], colors');
    
    drawnow();
end
