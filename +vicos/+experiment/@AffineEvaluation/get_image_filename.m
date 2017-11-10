function filename = get_image_filename (self, sequence, img)
    % filename = GET_IMAGE_FILENAME (self, sequence, img)
    %
    % Get full-path filename for specified image in specified sequence.
    %
    % Input:
    %  - self:
    %  - sequence: sequence name
    %  - img: image  number
    %
    % Output:
    %  - filename: full-path filename to image
    
    switch self.dataset_type
        case 'affine'
            % Oxford Affine dataset
            filename = fullfile(self.dataset_path, sequence, sprintf('img%d.ppm', img));
        case 'hpatches'
            % HPatches full-images dataset
            filename = fullfile(self.dataset_path, sequence, sprintf('%d.ppm', img));
        otherwise
            error('Unhandled dataset type: %s!', self.dataset_type)
    end
end