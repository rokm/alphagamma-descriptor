function fig = liberty_visualize_parameter_search_results (results, varargin)
    % fig = LIBERTY_VISUALIZE_PARAMETER_SEARCH_RESULTS (results, varargin)
    %
    % Visualizes the results of scale-related parameter search on Liberty
    % dataset.
    %
    % Input:
    %  - results: filename of results to load or results structure, either
    %    produced by the LIBERTY_FIND_OPTIMAL_PARAMETERS() call
    %
    % Output:
    %  - fig: handle of resulting figure
    %
    % (C) 2015 Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    % Load results
    if ~exist('results', 'var') || isempty(results),
        [ filename, pathname ] = uigetfile('*.mat', 'Pick a results file', 'MultiSelect', 'on');
        if isequal(filename, 0),
            return;
        end
        
        % Allow multiple files to be selected
        if iscell(filename),
            fig = cell(1, numel(filename));
            for p = 1:numel(filename),
                results = fullfile(pathname, filename{p});
                fig{p} = liberty_visualize_parameter_search_results(results, varargin{:});
            end
        
            return;
        else
            results = fullfile(pathname, filename);
        end
    end
    
    if ischar(results),
        results = load(results);
    end
    
    % Determine data dimensions
    num_repetitions = size(results.recognition_rate, 1);
    num_values = size(results.recognition_rate, 2);
    num_patchsets = size(results.recognition_rate, 3);
    
    % Compute mean and std
    recognition_rate_mean = mean(results.recognition_rate, 1);
    recognition_rate_std = std(results.recognition_rate, [], 1);
    
    recognition_rate_mean = reshape(recognition_rate_mean, num_values, num_patchsets);
    recognition_rate_std = reshape(recognition_rate_std, num_values, num_patchsets);
    
    % Plot
    legend_entries = cell(1, num_patchsets);
    h = nan(1, num_patchsets);
    
    fig = figure();
    for n = 1:num_patchsets, 
        h(n) = errorbar(results.parameter_values, 100*recognition_rate_mean(:,n), 100*recognition_rate_std(:,n));
        hold on;
        
        legend_entries{n} = sprintf('#%d', results.patchset_sizes(n));
    end
    
    title(results.experiment_title);
    xlabel(results.parameter_description);
    xlim([ results.parameter_values(1), results.parameter_values(end) ]);
    ylabel('Recognition rate [%]');
    ylim([ 0, 100 ]);
    grid on;
    legend(h, legend_entries);
end