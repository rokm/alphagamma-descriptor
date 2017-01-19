function filename = construct_image_filename (self, image_set, image_number, light_number)
    % filename = CONSTRUCT_IMAGE_FILENAME (self, set_number, image_number, light_number)
    %
    % Constructs image filename, given the set (sequence) number,
    % image number in the sequence, and lighting preset number.
    %
    % Input:
    %  - self:
    %  - image_set: image set (sequence)
    %  - image_number: image number
    %  - light_number: light preset number
    %
    % Output:
    %  - filename: image filename
    
    image_dir = sprintf('SET%03d', image_set);
    image_name = sprintf('Img%03d_%02d.bmp', image_number, light_number);
    
    filename = fullfile(self.dataset_path, image_dir, image_name);
end