function filename = construct_cache_filename (self, cache_dir, set_number, image_number, light_number, suffix)
    % filename = CONSTRUCT_CACHE_FILENAME (self, cache_dir, set_number, image_number, light_number, suffix)
    %
    % Constructs cache filename, given the set (sequence) number,
    % image number in the sequence, and lighting preset number.
    %
    % Input:
    %  - self:
    %  - cache_dir: cache directory
    %  - image_set: image set (sequence)
    %  - image_number: image number
    %  - light_number: light preset number
    %  - suffix: optional suffix to append to the basename
    %
    % Output:
    %  - filename: image filename
    
    % Default suffix
    if ~exist('suffix', 'var')
        suffix = '';
    end
    
    % Construct basename
    basename = sprintf('SET%03d_Img%03d_%02d', set_number, image_number, light_number);
    
    % Construct full filename
    filename = fullfile(cache_dir, [ basename, suffix ]);
end