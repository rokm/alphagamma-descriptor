function str = get_arch_id ()
    % str = GET_ARCH_ID ()
    %
    % Retrieves OpenCV arch identifier for Windows platforms (i.e., x86 for
    % win32 and x64 for win64). For other platforms, an empty string is 
    % returned.
    %
    % This function is primarily aimed for determining OpenCV library or 
    % binary path in build/configuration scripts.
    
    if ispc()
        if isequal(computer('arch'), 'win64')
            str = 'x64';
        else
            str = 'x86';
        end
    else
        str = '';
    end
end
