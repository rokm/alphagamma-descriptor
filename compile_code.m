function compile_code ()
    % COMPILE_CODE ()
    %
    % Compile Matlab/MEX dependencies.
    
    root_directory = fileparts(mfilename('fullpath'));
    fprintf('*** Compiling Matlab/MEX dependencies; root path: %s ***\n', root_directory);
    
    %% vicos.descriptor.AlphaGamma
    % OpenCV
    opencv_bin_dir = fullfile(root_directory, 'external', 'opencv-bin');
    opencv_include_dir = fullfile(opencv_bin_dir, 'include');

    if ispc()
        % Windows
        opencv_library_dir = fullfile(opencv_bin_dir, vicos.utils.opencv.get_arch_id(), vicos.utils.opencv.get_compiler_id(), 'lib');
        opencv_libs = '-lopencv_core341';
    else
        % Linux
        opencv_library_dir = fullfile(opencv_bin_dir, 'lib64');
        opencv_libs = '-lopencv_core';
    end
    
    % Source directory
    src_dir = '+vicos/+descriptor/@AlphaGamma/private';
    src_dir = fullfile(root_directory, src_dir);
    
    % Extra options
    if ~verLessThan('matlab', '9.4')
        % R2018a or newer; use R2017b API (separate complex API)
        mex_options = '-R2017b';
    else
        % For some reason, -R2017b and -largeArrayDims seem to be mutually
        % exclusive, so specify it only if we are not specifying -R2017b
        mex_options = '-largeArrayDims';
    end
    
    % alpha_gamma_distances_fast.cpp
    src_file = fullfile(src_dir, 'alpha_gamma_distances_fast.cpp');
    mex(mex_options, 'CXXFLAGS="$CXXFLAGS -Wall -mpopcnt"', sprintf('-I"%s"', opencv_include_dir), sprintf('-L"%s"', opencv_library_dir), opencv_libs, src_file, '-outdir', src_dir);
    
    % convert_bytestring_to_bitstring.cpp
    src_file = fullfile(src_dir, 'convert_bytestring_to_bitstring.cpp');
    mex(mex_options, 'CXXFLAGS="$CXXFLAGS -Wall"', sprintf('-I"%s"', opencv_include_dir), sprintf('-L"%s"', opencv_library_dir), opencv_libs, src_file, '-outdir', src_dir);
end
