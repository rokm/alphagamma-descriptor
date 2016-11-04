function startup()
    % Get root directory
    root_dir = fileparts(mfilename('fullpath'));

    addpath(root_dir);

    % mexopencv
    addpath( fullfile(root_dir, 'external', 'mexopencv') );

    % tight subplot
    addpath( fullfile(root_dir, 'external', 'tight_subplot') );
end
