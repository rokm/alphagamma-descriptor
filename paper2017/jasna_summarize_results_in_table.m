function jasna_summarize_results_in_table (cache_dir, sequences, varargin)
    % JASNA_SUMMARIZE_RESULTS_IN_TABLE (cache_dir, sequences, varargin)
    %
    % Gathers the results of JASNA_EXPERIMENT_AFFINE(), 
    % JASNA_EXPERIMENT_DTU(), and JASNA_EXPERIMENT_WEBCAM(), and summarizes
    % them in a table format.
    %
    % Input:
    %  - cache_dir: cache directory with results
    %  - sequences: cell array of sequence names; must correspond to base 
    %    names of result (e.g., 'graffiti' for
    %    Affine, 'SET007' for DTU, 'Frankfurt' for WebCam)
    %  - varargin: optional key/value pairs:
    %     - use_unique: whether to use unique matches instead of all
    %       (default: false)
    %     - compute_overall: compute and display average of measures across 
    %       all sequences instead of individual per-sequence values
    %       (default: false)
    
    % Parser
    parser = inputParser();
    parser.addParameter('use_unique', false, @islogical);
    parser.addParameter('compute_overall', false, @islogical);
    parser.addParameter('latex', false, @islogical);
    parser.addParameter('output_file', '', @ischar);
    parser.parse(varargin{:});
    
    use_unique = parser.Results.use_unique;
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
            results_map(experiment_id) = process_results(results, use_unique);
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
            overall = struct('putative_match_ratio', zeros(1, numel(sequences)), ...
                             'precision', zeros(1, numel(sequences)), ...
                             'matching_score', zeros(1, numel(sequences)), ...
                             'recall', zeros(1, numel(sequences)), ...
                             'recognition_rate', zeros(1, numel(sequences)), ...
                             'correct_matches', zeros(1, numel(sequences)), ...
                             'correspondences', zeros(1, numel(sequences)), ...
                             'precision_over_60', zeros(1, numel(sequences)));
                         
            % Gather
            for i = 1:numel(sequences)
                results = results_maps{i}(experiment_id);
                
                overall.putative_match_ratio(i) = mean(results.putative_match_ratio);
                overall.precision(i) = mean(results.precision);
                overall.matching_score(i) = mean(results.matching_score);
                overall.recall(i) = mean(results.recall);
                overall.recognition_rate(i) = mean(results.recognition_rate);
                overall.correct_matches(i) = mean(results.correct_matches);
                overall.correspondences(i) = mean(results.correspondences);
                overall.precision_over_60(i) = mean(results.precision_over_60);
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
    fprintf(fid, 'Avg. num. correspondences\t');
    fprintf(fid, 'Avg. putative match ratio\t');
    fprintf(fid, 'Avg. precision\t');
    fprintf(fid, 'Avg. matching score\t');
    fprintf(fid, 'Avg. recall\t');
    fprintf(fid, 'Avg. recog. rate\t');
    fprintf(fid, 'Avg. num. correct. matches\t');
    fprintf(fid, 'Avg. img. pairs with prec. >= 60%%\n');
    
    % Print results
    for j = 1:numel(experiment_ids)
        experiment_id = experiment_ids{j};
        
        if isempty(experiment_id)
            continue; % Ignore keypoint separators
        end
        
        results = results_map(experiment_id);
        
        fprintf(fid, '%s\t', experiment_id);
        fprintf(fid, '%d\t', round(mean(results.correspondences)));
        fprintf(fid, '%.2f\t', 100*mean(results.putative_match_ratio));
        fprintf(fid, '%.2f\t', 100*mean(results.precision));
        fprintf(fid, '%.2f\t', 100*mean(results.matching_score));
        fprintf(fid, '%.2f\t', 100*mean(results.recall));
        fprintf(fid, '%.2f\t', 100*mean(results.recognition_rate));
        fprintf(fid, '%.0f\t', mean(results.correct_matches));
        fprintf(fid, '%.2f\n', 100*mean(results.precision_over_60));
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
    fprintf(fid, 'Avg.\\ num.\\ & '); % Average number of correspondences
    fprintf(fid, 'Avg.\\ putative & '); % Average putative match ratio
    fprintf(fid, 'Average & '); % Average precision
    fprintf(fid, 'Average & '); % Average matching score
    fprintf(fid, 'Average & '); % Average recall
    fprintf(fid, 'Average & '); % Average recognition rate
    fprintf(fid, 'Avg.\\ num.\\ & '); % Average number of correct matches
    fprintf(fid, 'Avg.\\ img.\\ pairs \\\\\n'); % Average number of image pairs with precision >= 60%
    
    fprintf(fid, ' & '); % Combination
    fprintf(fid, 'corresp. & '); % Average number of correspondences
    fprintf(fid, 'match ratio & '); % Average putative match ratio
    fprintf(fid, 'precision & '); % Average precision
    fprintf(fid, 'matching score & '); % Average matching score
    fprintf(fid, 'recall & '); % Average recall
    fprintf(fid, 'recog.\\ rate & '); % Average recognition rate
    fprintf(fid, 'corr.\\ matches & '); % Average number of correct matches
    fprintf(fid, 'with prec.\\ >= 60\\%% \\\\\n'); % Average number of image pairs with precision >= 60%
    
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
        fprintf(fid, '%d & ', round(mean(results.correspondences)));
        fprintf(fid, '%.2f & ', 100*mean(results.putative_match_ratio));
        fprintf(fid, '%.2f & ', 100*mean(results.precision));
        fprintf(fid, '%.2f & ', 100*mean(results.matching_score));
        fprintf(fid, '%.2f & ', 100*mean(results.recall));
        fprintf(fid, '%.2f & ', 100*mean(results.recognition_rate));
        fprintf(fid, '%.0f & ', mean(results.correct_matches));
        fprintf(fid, '%.2f \\\\\n', 100*mean(results.precision_over_60));
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



function output = process_results (results, use_unique)
    if ~exist('use_unique', 'var') || isempty(use_unique)
        use_unique = false;
    end
    
    % Putative match ratio: number of putative matches / number of
    % keypoints
    if use_unique
        num_keypoints_unique = min([ results.num_keypoints_in_ref_unique; results.num_keypoints_in_test_unique ]);
        output.putative_match_ratio = [ results.num_putative_matches_unique ] ./ num_keypoints_unique;
    else
        num_keypoints = min([ results.num_keypoints_in_ref; results.num_keypoints_in_test ]);
        output.putative_match_ratio = [ results.num_putative_matches ] ./ num_keypoints;
    end
    output.putative_match_ratio(~isfinite(output.putative_match_ratio)) = 0; % NaN, Inf -> 0

    % Precision: number of correct matches / number of putative matches
    if use_unique
        output.precision = [ results.num_correct_matches_unique ] ./ [ results.num_putative_matches_unique ];
    else
        output.precision = [ results.num_correct_matches ] ./ [ results.num_putative_matches ];
    end
    output.precision(~isfinite(output.precision)) = 0; % NaN, Inf -> 0

    % Matching score: number of correct matches / number of keypoints
    if use_unique
        num_keypoints_unique = min([ results.num_keypoints_in_ref_unique; results.num_keypoints_in_test_unique ]);
        output.matching_score = [ results.num_correct_matches_unique ] ./ num_keypoints_unique;
    else
        num_keypoints = min([ results.num_keypoints_in_ref; results.num_keypoints_in_test ]);
        output.matching_score = [ results.num_correct_matches ] ./ num_keypoints;
    end
    output.matching_score(~isfinite(output.matching_score)) = 0; % NaN, Inf -> 0
    
    % Recall: number of correct matches / number of correspondences
    if use_unique
        output.recall = [ results.num_correct_matches_unique ] ./ [ results.num_consistent_correspondences_unique ];
    else
        output.recall = [ results.num_correct_matches ] ./ [ results.num_consistent_correspondences ];
    end
    output.recall(~isfinite(output.recall)) = 0; % NaN, Inf -> 0
    
    % Recognition rate: number of correct matches / number of correspondences
    if use_unique
        output.recognition_rate = [ results.num_consistent_matches_unique ] ./ [ results.num_consistent_correspondences_unique ];
    else
        output.recognition_rate = [ results.num_consistent_matches ] ./ [ results.num_consistent_correspondences ];
    end
    output.recognition_rate(~isfinite(output.recognition_rate)) = 0; % NaN, Inf -> 0

    % Correct matches
    if use_unique
        output.correct_matches = [ results.num_correct_matches_unique ];
    else
        output.correct_matches = [ results.num_correct_matches ];
    end
    output.correct_matches(~isfinite(output.correct_matches)) = 0; % NaN, Inf -> 0

    % Correspondences
    if use_unique
        output.correspondences = [ results.num_consistent_correspondences_unique ];
    else
        output.correspondences = [ results.num_consistent_correspondences ];
    end
    output.correspondences(~isfinite(output.correspondences)) = 0; % NaN, Inf -> 0
    
    % Compute portion of image pairs with precision over 60%
    output.precision_over_60 = sum(output.precision > 0.6) / numel(output.precision);
    output.precision_over_60(~isfinite(output.precision_over_60)) = 0; % NaN, Inf -> 0
end

