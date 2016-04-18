function jasna_pami_create_table ()
    %[ filenames, pathname ] = uigetfile({ '*.mat','MAT-files (*.mat)' }, 'Select results files', 'MultiSelect', 'on');
    %if isequal(filenames, 0),
    %    return;
    %end
    %filenames = cellfun(@(x) fullfile(pathname, x), filenames, 'UniformOutput', false);
    
    filenames = { '/home/rok/Projects/jasna/code/results-final-inf/pairs-oriented/boat-brisk.mat', ...
    ...%'/home/rok/Projects/jasna/code/results-final-inf/pairs-oriented/boat-kaze.mat', ...
    '/home/rok/Projects/jasna/code/results-final-inf/pairs-oriented/boat-orb.mat', ...
    '/home/rok/Projects/jasna/code/results-final-inf/pairs-oriented/boat-sift.mat', ...
    '/home/rok/Projects/jasna/code/results-final-inf/pairs-oriented/boat-surf.mat' };
    
    %% Load
    for i = 1:numel(filenames),
        all_results(i) = load(filenames{i});
    end
    
    sort_order_rows = { 'sift', 'surf', 'brisk', 'kaze', 'orb' };
    
    sort_order_cols = {
        'U-SIFT', 'O-SIFT', ...
        'U-SURF', 'O-SURF', ...
        'U-BRISK', 'O-BRISK', ...
        'U-KAZE64', 'O-KAZE64', ...
        'U-ORB32', 'O-ORB32', ...
        'U-BRIEF64', 'O-BRIEF64', ...
        'U-LATCH64', 'O-LATCH64', ...
        'U-FREAK', 'O-FREAK', ...
        'SU-FREAK', 'SO-FREAK', ...
        'U-AG basic', 'O-AG basic', ...
        'U-AG60', 'O-AG60', ...
        'SU-AG60', 'SO-AG60' ...
    };

    % Create header
    table = cell(1+numel(sort_order_rows), 2+numel(sort_order_cols));
    for i = 1:numel(sort_order_cols),
        table{1, 2+i} = sort_order_cols{i};
    end
    for i = 1:numel(sort_order_rows),
        table{1+i, 1} = sort_order_rows{i};
    end

    %% Fill table
    for i = 1:numel(all_results),
        results = all_results(i);
        
        points_name = results.experiment.name;
        points_name = strrep(points_name, 'u-', '');
        row_idx = find(ismember(sort_order_rows, points_name));
        if isempty(row_idx),
            warning('Unhandled point type: "%s"', results.experiment.name);
            continue;
        end
        
        %experiments{row_idx+1, 1} = points_name;
        table{row_idx+1, 2} = sum([results.num_established_correspondences]);
        
        %% Process results
        num_repetitions = size(results.recognition_rates, 1);
        num_descriptors = size(results.recognition_rates, 2);
        num_values = size(results.recognition_rates, 3);
        
        %% Compute mean and std
        recognition_rates_mean = mean(results.recognition_rates, 1);
        recognition_rates_std = std(results.recognition_rates, [], 1);
    
        recognition_rates_mean = reshape(recognition_rates_mean, num_descriptors, num_values);
        recognition_rates_std = reshape(recognition_rates_std, num_descriptors, num_values);
        
        recognition_rates_mean_mean = mean(recognition_rates_mean, 2); % Over values
        
        for d = 1:num_descriptors,
            col_idx = find(ismember(sort_order_cols, results.experiment.descriptors(d).name));
            table{1+row_idx, 2 + col_idx} = recognition_rates_mean_mean(d);
        end
    end
    
    
    %% Remove unused columns and rows    
    empty = cellfun(@isempty, table);
    
    empty_rows = all( empty(:, 3:end), 2 );
    empty_cols = all( empty(2:end, :), 1 );

    table(empty_rows,:) = [];
    table(:,empty_cols) = [];
    
    %% Print LaTeX table
    fprintf('\n\n');
    
    fprintf('\\begin{tabular}{');
    for i = 1:size(table,2),
        if i == 1,
            fprintf('l');
        else
            fprintf('c');
        end
    end
    fprintf('}\n');
    fprintf('\\toprule\n');
    
    % Header
    fprintf('&');
    for i = 3:size(table,2),
        % First column: name + number of points
        fprintf(' %s', table{1,i});
        if i < size(table,2),
            fprintf(' &');
        else
            fprintf('\\\\\n');
        end
    end
    fprintf('\\midrule\n');
    
    % Contents
    for i = 2:size(table, 1);
        fprintf('%s (%d)', table{i, 1}, table{i, 2});
        
        % Results
        for j = 3:size(table,2),
            if isempty(table{i,j}),
                fprintf(' & -');
            else
                fprintf(' & %.2f', 100*table{i,j});
            end
        end
        
        fprintf('\\\\\n');
    end

    fprintf('\\bottomrule\n');
    fprintf('\\end{tabular}\n');

    fprintf('\n\n');
    
    
    table
end