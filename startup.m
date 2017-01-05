function startup ()
    % Root directory
    root_dir = fileparts(mfilename('fullpath'));

    %% This folder
    addpath(root_dir);

    % mexopencv
    addpath( fullfile(root_dir, 'external', 'mexopencv') );

    % lapjv
    addpath( fullfile(root_dir, 'external', 'lapjv') );

    % tight subplot
    addpath( fullfile(root_dir, 'external', 'tight_subplot') );

    %% Turn off warnings
    % Image size warning
    warning('off', 'Images:initSize:adjustingMag');
end
