% Get root directory
root_dir = fileparts(mfilename('fullpath'));

% mexopencv
addpath( fullfile(root_dir, 'external', 'mexopencv') );

% tight subplot
addpath( fullfile(root_dir, 'external', 'tight_subplot') );
