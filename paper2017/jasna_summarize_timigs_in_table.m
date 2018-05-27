function jasna_summarize_timigs_in_table (cache_dir, sequences, varargin)
    % JASNA_SUMMARIZE_TIMINGS_IN_TABLE (cache_dir, sequences, varargin)
    %
    % Gathers the results of JASNA_EXPERIMENT_AFFINE(), 
    % JASNA_EXPERIMENT_DTU(), and JASNA_EXPERIMENT_WEBCAM(), and summarizes
    % the (amortized) run-times in a table format.
    %
    % Input:
    %  - cache_dir: cache directory with results
    %  - sequences: cell array of sequence names; must correspond to base 
    %    names of result (e.g., 'graffiti' for
    %    Affine, 'SET007' for DTU, 'Frankfurt' for WebCam)
    %  - varargin: optional key/value pairs:
    %     - compute_overall: compute and display average of measures across 
    %       all sequences instead of individual per-sequence values
    %       (default: false)
    
    % Parser
    parser = inputParser();
    parser.addParameter('compute_overall', false, @islogical);
    parser.addParameter('latex', false, @islogical);
    parser.addParameter('output_file', '', @ischar);
    parser.parse(varargin{:});
    
    compute_overall = parser.Results.compute_overall;
    latex = parser.Results.latex;
    output_file = parser.Results.output_file;
    
    overall_name = 'overall';
  
    % If only one sequence is given, make it into cell array
    if ~iscell(sequences)
        sequences = { sequences };
    end
    
    %% Process
    results_maps = cell(1, numel(sequences));
    for i = 1:numel(sequences)
        sequence = sequences{i};

        results_map = containers.Map();
        
        % Gather all results
        result_files = dir(fullfile(cache_dir, sprintf('%s_*.mat', sequence)));
        
        for f = 1:numel(result_files)
            results_file = fullfile(result_files(f).folder, result_files(f).name);
            
            [ ~, basename ] = fileparts(result_files(f).name);
            experiment_id = sscanf(basename, [ sequence, '_%s' ]);
                        
            % Load
            results = load(results_file); results = results.results;
            
            % Store
            results_map(experiment_id) = process_results(results);
        end

        results_maps{i} = results_map;
    end
       
    % Do we need to compute average across sequences? If so, do it and
    % override the sequences name to overall_name at the end...
    if compute_overall
        overall_map = containers.Map();
        
        keys = results_maps{1}.keys();
        
        for e = 1:numel(keys)
            experiment_id = keys{e};
            
            % Initialize
            overall = struct('time_per_keypoint', [], ...
                             'time_per_descriptor', [], ...
                             'time_per_distance', []);
                         
            % Gather
            for i = 1:numel(sequences)
                results = results_maps{i}(experiment_id);
                
                overall.time_per_keypoint = [ overall.time_per_keypoint, results.time_per_keypoint ];
                overall.time_per_descriptor = [ overall.time_per_descriptor, results.time_per_descriptor ];
                overall.time_per_distance = [ overall.time_per_distance, results.time_per_distance ];
            end
            
            % Store
            overall_map(experiment_id) = overall;
        end
        
        % Override for display code below...
        results_maps = { overall_map };
        sequences = { overall_name };
    end
    
    
    %% Display
    % Open output file
    if ~isempty(output_file)
        vicos.utils.ensure_path_exists(output_file);
        fid = fopen(output_file, 'w+');
    else
        fid = 1;
    end
    
    % Display/write table(s)
    for i = 1:numel(sequences)
        if latex
            display_table_latex(sequences{i}, results_maps{i}, fid);
        else
            display_table(sequences{i}, results_maps{i}, fid);
        end
    end
    
    % Close file
    if fid ~= 1
        fclose(fid);
    end
end


function display_table (sequence, results_map, fid)
    
    % Sort experiment IDs
    experiment_ids = sort_experiment_ids(results_map.keys());
    
    % Print header
    fprintf(fid, '\n\n*** Sequence: %s ***\n', sequence);
    
    fprintf(fid, 'Combination\t');
    fprintf(fid, 'Avg. amort. time for keypoint detection [ms]\t');
    fprintf(fid, 'Avg. amort. time for descriptor extraction [ms]\t');
    fprintf(fid, 'Avg. amort. time for distance computation [us]\n');
        
    % Print results
    for j = 1:numel(experiment_ids)
        experiment_id = experiment_ids{j};
        
        if isempty(experiment_id)
            continue; % Ignore keypoint separators
        end
        
        results = results_map(experiment_id);
        
        fprintf(fid, '%s\t', experiment_id);
        fprintf(fid, '%.3f +/- %.3f\t', 1000*mean(results.time_per_keypoint), 1000*std(results.time_per_keypoint));
        fprintf(fid, '%.3f +/- %.3f\t', 1000*mean(results.time_per_descriptor), 1000*std(results.time_per_descriptor));
        fprintf(fid, '%.3f +/- %.3f\n', 1000000*mean(results.time_per_distance), 1000000*std(results.time_per_distance));
    end
end


function display_table_latex (sequence, results_map, fid)
    
    % Sort experiment IDs
    experiment_ids = sort_experiment_ids(results_map.keys());
    
    % Print header
    fprintf(fid, '\n\n%% *** Sequence: %s ***\n', sequence);
    
    fprintf(fid, '\\begin{tabular}{l c cccc c c c}\n');
    
    fprintf(fid, '\\toprule\n');
      
    fprintf(fid, 'Combination & '); % Combination
    fprintf(fid, 'Keypoint detection [\\si{\\milli\\second}] & '); % Average amortized time for keypoint detection [ms]
    fprintf(fid, 'Descriptor extraction [\\si{\\milli\\second}] & '); % Average amortized time for descriptor extraction [ms]
    fprintf(fid, 'Distance computation [\\si{\\micro\\second}] \\\\\n'); % Average amortized time for distance computation [us]
       
    fprintf(fid, '\\midrule\n');
    
    % Print results
    for j = 1:numel(experiment_ids)
        experiment_id = experiment_ids{j};
        
        if isempty(experiment_id)
            fprintf(fid, '\\midrule\n'); % Print keypoint separator line
            continue;
        end
        
        results = results_map(experiment_id);
        
        fprintf(fid, '%s & ', experiment_id);
        fprintf(fid, '\\SI{%.3f \\pm %.3f}{} & ', 1000*mean(results.time_per_keypoint), 1000*std(results.time_per_keypoint));
        fprintf(fid, '\\SI{%.3f \\pm %.3f}{} & ', 1000*mean(results.time_per_descriptor), 1000*std(results.time_per_descriptor));
        fprintf(fid, '\\SI{%.3f \\pm %.3f}{} \\\\\n', 1000000*mean(results.time_per_distance), 1000000*std(results.time_per_distance));
    end
        
    fprintf(fid, '\\bottomrule\n');
    
    fprintf(fid, '\\end{tabular}\n');
end


function sorted_ids = sort_experiment_ids (ids)
    % Split IDs
    split_ids = cellfun(@(x) strsplit(x, '+'), ids, 'UniformOutput', false);
    split_ids = vertcat(split_ids{:});
    
    keypoint_map = containers.Map();
    
    for i = 1:size(split_ids, 1)
        keypoint_id = split_ids{i, 1};
        descriptor_id = split_ids{i, 2};
        
        if ~keypoint_map.isKey(keypoint_id)
            keypoint_map(keypoint_id) = containers.Map();
        end
        descriptor_map = keypoint_map(keypoint_id);
        
        descriptor_map(descriptor_id) = true; % Does MATLAB have sets?
    end

    sorted_ids = {};
    
    % Sort keypoint detectors alphabetically
    detector_ids = sort(keypoint_map.keys());
    
    for i = 1:numel(detector_ids)
        detector_id = detector_ids{i};
        descriptor_map = keypoint_map(detector_id);
        
        % Beginning of the list: native descriptor
        list_front = {};
        
        if i > 1
            list_front{end+1} = ''; % Signal division between different keypoints
        end
        
        if descriptor_map.isKey(detector_id)
            descriptor_map.remove(detector_id);
            list_front{end+1} = sprintf('%s+%s', detector_id, detector_id);
        end
        
        % End of the list: AG and AGS
        list_back = {};
        
        if descriptor_map.isKey('AG')
            descriptor_map.remove('AG');
            list_back{end+1} = sprintf('%s+AG', detector_id);
        end
        
        if descriptor_map.isKey('AGS')
            descriptor_map.remove('AGS');
            list_back{end+1} = sprintf('%s+AGS', detector_id);
        end
        
        % In between: others, sorted alphabetically
        descriptor_ids = sort(descriptor_map.keys());
        list_middle = cellfun(@(x) sprintf('%s+%s', detector_id, x), descriptor_ids, 'UniformOutput', false);
        
        % Append
        sorted_ids = [ sorted_ids, list_front, list_middle, list_back ];
    end
end


function output = process_results (results)
    output.time_per_keypoint = [ results.time_per_keypoint ];
    output.time_per_descriptor = [ results.time_per_descriptor ];
    output.time_per_distance = [ results.time_per_distance ];
end
