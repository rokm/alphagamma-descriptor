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
    opencv_library_dir = fullfile(opencv_bin_dir, vicos.utils.opencv.get_arch_id(), vicos.utils.opencv.get_compiler_id(), 'lib');
    
    if ispc()
        opencv_libs = '-lopencv_core320';
    else
        opencv_libs = '-lopencv_core';
    end
    
    % Source directory
    src_dir = '+vicos/+descriptor/@AlphaGamma/private';
    src_dir = fullfile(root_directory, src_dir);
    
    % alpha_gamma_distances.cpp
    src_file = fullfile(src_dir, 'alpha_gamma_distances.cpp');
    mex('-largeArrayDims', 'CXXFLAGS="$CXXFLAGS -Wall"', sprintf('-I"%s"', opencv_include_dir), sprintf('-L"%s"', opencv_library_dir), opencv_libs, src_file, '-outdir', src_dir);
    
    % alpha_gamma_distances_fast.cpp
    src_file = fullfile(src_dir, 'alpha_gamma_distances_fast.cpp');
    mex('-largeArrayDims', 'CXXFLAGS="$CXXFLAGS -Wall -mpopcnt"', sprintf('-I"%s"', opencv_include_dir), sprintf('-L"%s"', opencv_library_dir), opencv_libs, src_file, '-outdir', src_dir);
    
    % convert_bytestring_to_bitstring.cpp
    src_file = fullfile(src_dir, 'convert_bytestring_to_bitstring.cpp');
    mex('-largeArrayDims', 'CXXFLAGS="$CXXFLAGS -Wall"', sprintf('-I"%s"', opencv_include_dir), sprintf('-L"%s"', opencv_library_dir), opencv_libs, src_file, '-outdir', src_dir);
end
