function str = get_compiler_id ()
    % str = GET_COMPILER_ID ()
    %
    % Retrieves OpenCV compiler identifier for Windows platforms. For other
    % platforms, an empty string is returned.
    %
    % This function is primarily aimed for determining OpenCV library or
    % binary path in build/configuration scripts.
    
    str = '';
    
    % Empty string on non-Windows platforms
    if ~ispc()
        return;
    end 
    
    % Get active C++ compiler
    cpp = mex.getCompilerConfigurations('C++', 'Selected');
    
    if strcmp(cpp.Manufacturer, 'Microsoft')
        if ~isempty(strfind(cpp.Name, 'Visual'))
            % Visual Studio
            switch cpp.Version
                case '14.0', str = 'vc14'; % VS2015
                case '12.0', str = 'vc12'; % VS2013
                case '11.0', str = 'vc11'; % VS2012
                case '10.0', str = 'vc10'; % VS2010
                case '9.0',  str = 'vc9'; % VS2008
                case '8.0',  str = 'vc8'; % VS2005
                otherwise, error('Unsupported Visual Studio version: %s', cpp.Version);
            end
        elseif ~isempty(strfind(cpp.Name, 'SDK'))
            % Windows SDK
            switch cpp.Version
                case '10.0', str = 'vc14'; % VS2015
                case '8.1',  str = 'vc12'; % VS2013
                case '8.0',  str = 'vc11'; % VS2012
                case '7.1',  str = 'vc10'; % VS2010
                case {'7.0', '6.1'}, str = 'vc9'; % VS2008
                case '6.0', str = 'vc8'; % VS2005
                otherwise, error('Unsupported Windows SDK version: %s', cpp.Version);
            end
        end
    elseif strcmp(cpp.Manufacturer, 'GNU')
        % MinGW
        str = 'mingw';
    end
    
    if isempty(str)
        error('Unsupported compiler: %s', cpp.Name);
    end
end