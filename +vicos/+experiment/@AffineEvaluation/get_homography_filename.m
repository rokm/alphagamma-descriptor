function filename = get_homography_filename (self, sequence, img1, img2)
    % filename = GET_HOMOGRAPHY_FILENAME (self, sequence, img1, img2)
    %
    % Get full-path homography filename for specified images in specified 
    % sequence.
    %
    % Input:
    %  - self:
    %  - sequence: sequence name
    %  - img1: first image number (should always be 1)
    %  - img2: second image number
    %
    % Output:
    %  - filename: full-path filename to homography file
    
    switch self.dataset_type
        case 'affine'
            % Oxford Affine dataset
            filename = fullfile(self.dataset_path, sequence, sprintf('H%dto%dp', img1, img2));
        case 'hpatches'
            % HPatches full-images dataset
            filename = fullfile(self.dataset_path, sequence, sprintf('H_%d_%d', img1, img2));
        otherwise
            error('Unhandled dataset type: %s!', self.dataset_type)
    end
end