function jasna_display_results (cache_dir, sequences, varargin)
    % JASNA_DISPLAY_RESULTS (cache_dir, sequences, varargin)
    %
    % Displays the results of JASNA_EXPERIMENT_AFFINE(), 
    % JASNA_EXPERIMENT_DTU(), and JASNA_EXPERIMENT_WEBCAM().
    %
    % Input:
    %  - cache_dir: cache directory with results
    %  - sequences: cell array of sequence names; must correspond to base 
    %    names of result (e.g., 'graffiti' for
    %    Affine, 'SET007' for DTU, 'Frankfurt' for WebCam)
    %  - varargin: optional key/value pairs:
    %     - display_figure: display results in Matlab figure (default:
    %       true)
    %     - output_dir: output directory for TikZ/TeX code (default: '';
    %       disabled)
    %     - use_unique: whether to use unique matches instead of all
    %       (default: false)
    %     - compute_overall: compute and display average of measures across 
    %       all sequences instead of individual per-sequence values
    %       (default: false)
    %     - overall_name: name used for filename prefix used in overall
    %       mode (default: overall)
    
    % Parser
    parser = inputParser();
    parser.addParameter('display_figure', true, @islogical);
    parser.addParameter('output_dir', '', @ischar);
    parser.addParameter('use_unique', false, @islogical);
    parser.addParameter('compute_overall', false, @islogical);
    parser.addParameter('overall_name', 'overall', @ischar);
    parser.parse(varargin{:});
    
    display_figure = parser.Results.display_figure;
    output_dir = parser.Results.output_dir;
    use_unique = parser.Results.use_unique;
    compute_overall = parser.Results.compute_overall;
    overall_name = parser.Results.overall_name;
  
    % If only one sequence is given, make it into cell array
    if ~iscell(sequences)
        sequences = { sequences };
    end
    
    experiment_ids = { 'sift', 'rootsift', 'surf', 'kaze', 'brisk', 'radial', 'lift' }; % The IDs of experiments for which results are to be gathered
    
    %% Process
    results_maps = cell(1, numel(sequences));
    for i = 1:numel(sequences)
        sequence = sequences{i};

        results_map = containers.Map();
        
        % Gather all
        for e = 1:numel(experiment_ids)
            % Experiment parametrization
            experiment_id = experiment_ids{e};
            [ keypoint_detector, descriptor_extractor, alphagamma_float, alphagamma_short ] = jasna_get_experiment_definition(experiment_id);
       
            keypoint_detector = keypoint_detector(); % Create instance to get ID
            
            % Native experiment (if native descriptor extractor exists)
            if ~isempty(descriptor_extractor)
                descriptor_extractor = descriptor_extractor();
                results_file = fullfile(cache_dir, sprintf('%s_%s+%s.mat', sequence, keypoint_detector.identifier, descriptor_extractor.identifier));
                results = load(results_file); results = results.results;
                results_map(sprintf('%s', experiment_id)) = process_results(results, use_unique);
            end

            % AG-float
            alphagamma_float = alphagamma_float();
            results_file = fullfile(cache_dir, sprintf('%s_%s+%s.mat', sequence, keypoint_detector.identifier, alphagamma_float.identifier));
            results = load(results_file); results = results.results;
            results_map(sprintf('%s-ag', experiment_id)) = process_results(results, use_unique);

            % AG-short
            alphagamma_short = alphagamma_short();
            results_file = fullfile(cache_dir, sprintf('%s_%s+%s.mat', sequence, keypoint_detector.identifier, alphagamma_short.identifier));
            results = load(results_file); results = results.results;
            results_map(sprintf('%s-ags', experiment_id)) = process_results(results, use_unique);
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
            overall = struct('precision', zeros(1, numel(sequences)), ...
                             'recall', zeros(1, numel(sequences)), ...
                             'recognition_rate', zeros(1, numel(sequences)), ...
                             'correct_matches', zeros(1, numel(sequences)), ...
                             'correspondences', zeros(1, numel(sequences)), ...
                             'precision_over_60', zeros(1, numel(sequences)));
                         
            % Gather
            for i = 1:numel(sequences)
                results = results_maps{i}(experiment_id);
                
                overall.precision(i) = mean(results.precision);
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
    for i = 1:numel(sequences)
        sequence = sequences{i};
        results_map = results_maps{i};
        
        % Display figure
        if display_figure
            fig = figure('Name', sequence);
            ax = tight_subplot(1, 4, [ .05, .05 ], [ .1, .1 ], [ .1, .1 ]);

            % Average precision
            set(fig, 'CurrentAxes', ax(4));
            draw_figure(results_map, 'precision', 'title', 'Average Precision [%]', 'is_percent', true);

            % Average recall
            set(fig, 'CurrentAxes', ax(3));
            draw_figure(results_map, 'recall', 'title', 'Average Recall [%]', 'is_percent', true);

            % Average recognition rate
            set(fig, 'CurrentAxes', ax(1));
            draw_figure(results_map, 'recognition_rate', 'title', 'Average Recognition Rate [%]', 'is_percent', true);

            % Correct matches
            set(fig, 'CurrentAxes', ax(2));
            draw_figure(results_map, 'correct_matches', 'title', 'Average Number of Correct Matches', 'is_percent', false);

            drawnow();
            
            % Image pairs with precision > 60%
            fig = figure('Name', sprintf('%s: pairs with precision > 60%%', sequence));
            draw_figure(results_map, 'precision_over_60', 'title', 'Image pairs with precision > 60% [%]', 'is_percent', true, 'display_num_correspondences', false);
            drawnow();
        end
        
        % Export figure
        if ~isempty(output_dir)
            output_file = fullfile(output_dir, sprintf('%s_avg_precision.tex', sequence));
            export_figure_as_tikz(results_map, 'precision', 'title', 'Average Precision [%]', 'is_percent', true, 'output_filename', output_file);
            
            output_file = fullfile(output_dir, sprintf('%s_avg_recall.tex', sequence));
            export_figure_as_tikz(results_map, 'recall', 'title', 'Average Recall [%]', 'is_percent', true, 'output_filename', output_file);
            
            output_file = fullfile(output_dir, sprintf('%s_avg_recognition_rate.tex', sequence));
            export_figure_as_tikz(results_map, 'recognition_rate', 'title', 'Average Recognition Rate [%]', 'is_percent', true, 'output_filename', output_file);
            
            output_file = fullfile(output_dir, sprintf('%s_avg_correct_matches.tex', sequence));
            export_figure_as_tikz(results_map, 'correct_matches', 'title', 'Average Number of Correct Matches', 'is_percent', false, 'output_filename', output_file);
            
            output_file = fullfile(output_dir, sprintf('%s_precision_over_60.tex', sequence));
            export_figure_as_tikz(results_map, 'precision_over_60', 'title', 'Image pairs with precision > \SI{60}{%} [%]', 'is_percent', true, 'output_filename', output_file, 'display_num_correspondences', false);
        end
    end
end


function draw_figure (results_map, field_name, varargin)
    parser = inputParser();
    parser.addParameter('title', '', @ischar);
    parser.addParameter('is_percent', true, @islogical);
    parser.addParameter('display_num_correspondences', true, @islogical);
    parser.parse(varargin{:});
    
    title_str = parser.Results.title;
    is_percent = parser.Results.is_percent;
    display_num_correspondences = parser.Results.display_num_correspondences;
    
    % Bunch of more-or-less hard-coded stuff, because our graphs have fixed
    % appearance...
    entries = { 'sift', 'rootsift', 'sift-ag', 'sift-ags', 'surf', 'surf-ag', 'surf-ags', 'kaze', 'kaze-ag', 'kaze-ags', 'brisk', 'brisk-ag', 'brisk-ags', 'lift', 'lift-ag', 'lift-ags', 'radial-ag', 'radial-ags' };
    xticks = [ 2.5, 6, 9, 12, 15, 17.5 ];
    x_limit = [ 0, 19 ];
    
    if display_num_correspondences
        fmt = '%s\\newline(%d)';
        xticklabels = { ...
            sprintf(fmt, 'SIFT',   round(mean(results_map('sift').correspondences))), ...
            sprintf(fmt, 'SURF',   round(mean(results_map('surf').correspondences))), ...
            sprintf(fmt, 'KAZE',   round(mean(results_map('kaze').correspondences))), ...
            sprintf(fmt, 'BRISK',  round(mean(results_map('brisk').correspondences))), ...
            sprintf(fmt, 'LIFT',   round(mean(results_map('lift').correspondences))), ...
            sprintf(fmt, 'RADIAL', round(mean(results_map('radial-ag').correspondences))) };
    else
        xticklabels = { 'SIFT', 'SURF', 'KAZE', 'BRISK', 'LIFT', 'RADIAL' };
    end
    
    % Colormap
    colormap = [ ...
        1.0000,0,0;
        0.9294,0.4902,0.1923;
        1.0000,0.7529,0;
        0.9000,0.65,0.4;
        0.6200,0.1,0.6;
        0.7000,0.3,0.4;
        1.0000,0.6961,0.8;
        0.4000,0.20,0;
        0.6000, 0.3, 0;
        0.7529,0.5647,0;
        0.0000,0,0.5961;
        0.0000,0,1;
        0.2000,0.6,1;
        0.2196,0.3412,0.1373;
        0.2000,0.5176,0.2;
        0.5725,0.8157,0.3137;
        0.8000,0.0,0.0;
        0.6000,0,0.1294 ];
    
    % Plot bars
    for e = 1:numel(entries)
        avg_value = mean(results_map(entries{e}).(field_name));
        if is_percent
            avg_value = 100*avg_value;
        end
        
        h = bar(e, avg_value); hold on;
        set(h, 'FaceColor', colormap(e,:), 'BarWidth', 0.7, 'LineStyle', 'none');
    end
    if is_percent
        ylim([ 0, 100 ]);
    end
    xlim(x_limit);
    set(gca, 'YGrid', 'on', 'XTick', xticks, 'XTickLabel', xticklabels);
    title(title_str);
end

function export_figure_as_tikz (results_map, field_name, varargin)
    parser = inputParser();
    parser.addParameter('title', '', @ischar);
    parser.addParameter('is_percent', true, @islogical);
    parser.addParameter('display_num_correspondences', true, @islogical);
    parser.addParameter('output_filename', '', @ischar);
    parser.parse(varargin{:});
    
    title_str = parser.Results.title;
    is_percent = parser.Results.is_percent;
    display_num_correspondences = parser.Results.display_num_correspondences;
    output_filename = parser.Results.output_filename;
    
    % Load template
    template= fullfile(fileparts(mfilename('fullpath')), 'bargraph.tmpl.tex');
    template_str = fileread(template);
        
    % Substitute x-tick labels
    if display_num_correspondences
        % label + number of correspondences
        fmt = '\\textbf{%s}\\\\%d';
        template_str = strrep(template_str, '$$TICK_SIFT$$',   sprintf(fmt, 'SIFT',   round(mean(results_map('sift').correspondences))));
        template_str = strrep(template_str, '$$TICK_SURF$$',   sprintf(fmt, 'SURF',   round(mean(results_map('surf').correspondences))));
        template_str = strrep(template_str, '$$TICK_KAZE$$',   sprintf(fmt, 'KAZE',   round(mean(results_map('kaze').correspondences))));
        template_str = strrep(template_str, '$$TICK_BRISK$$',  sprintf(fmt, 'BRISK',  round(mean(results_map('brisk').correspondences))));
        template_str = strrep(template_str, '$$TICK_LIFT$$',   sprintf(fmt, 'LIFT',   round(mean(results_map('lift').correspondences))));
        template_str = strrep(template_str, '$$TICK_RADIAL$$', sprintf(fmt, 'RADIAL', round(mean(results_map('radial-ag').correspondences))));
    else
        template_str = strrep(template_str, '$$TICK_SIFT$$',   'SIFT');
        template_str = strrep(template_str, '$$TICK_SURF$$',   'SURF');
        template_str = strrep(template_str, '$$TICK_KAZE$$',   'KAZE');
        template_str = strrep(template_str, '$$TICK_BRISK$$',  'BRISK');
        template_str = strrep(template_str, '$$TICK_LIFT$$',   'LIFT');
        template_str = strrep(template_str, '$$TICK_RADIAL$$', 'RADIAL');
    end
    
    % Substitute values
    if is_percent
        scale = 100;
    else
        scale = 1;
    end
    
    template_str = strrep(template_str, '$$VALUE_SIFT$$',       sprintf('%g', scale*mean(results_map('sift').(field_name))));
    template_str = strrep(template_str, '$$VALUE_SIFT_ROOTSIFT$$', sprintf('%g', scale*mean(results_map('rootsift').(field_name))));
    template_str = strrep(template_str, '$$VALUE_SIFT_AG$$',    sprintf('%g', scale*mean(results_map('sift-ag').(field_name))));
    template_str = strrep(template_str, '$$VALUE_SIFT_AGS$$',   sprintf('%g', scale*mean(results_map('sift-ags').(field_name))));
    template_str = strrep(template_str, '$$VALUE_SURF$$',       sprintf('%g', scale*mean(results_map('surf').(field_name))));
    template_str = strrep(template_str, '$$VALUE_SURF_AG$$',    sprintf('%g', scale*mean(results_map('surf-ag').(field_name))));
    template_str = strrep(template_str, '$$VALUE_SURF_AGS$$',   sprintf('%g', scale*mean(results_map('surf-ags').(field_name))));
    template_str = strrep(template_str, '$$VALUE_KAZE$$',       sprintf('%g', scale*mean(results_map('kaze').(field_name))));
    template_str = strrep(template_str, '$$VALUE_KAZE_AG$$',    sprintf('%g', scale*mean(results_map('kaze-ag').(field_name))));
    template_str = strrep(template_str, '$$VALUE_KAZE_AGS$$',   sprintf('%g', scale*mean(results_map('kaze-ags').(field_name))));
    template_str = strrep(template_str, '$$VALUE_BRISK$$',      sprintf('%g', scale*mean(results_map('brisk').(field_name))));
    template_str = strrep(template_str, '$$VALUE_BRISK_AG$$',   sprintf('%g', scale*mean(results_map('brisk-ag').(field_name))));
    template_str = strrep(template_str, '$$VALUE_BRISK_AGS$$',  sprintf('%g', scale*mean(results_map('brisk-ags').(field_name))));
    template_str = strrep(template_str, '$$VALUE_LIFT$$',       sprintf('%g', scale*mean(results_map('lift').(field_name))));
    template_str = strrep(template_str, '$$VALUE_LIFT_AG$$',    sprintf('%g', scale*mean(results_map('lift-ag').(field_name))));
    template_str = strrep(template_str, '$$VALUE_LIFT_AGS$$',   sprintf('%g', scale*mean(results_map('lift-ags').(field_name))));
    template_str = strrep(template_str, '$$VALUE_RADIAL_AG$$',  sprintf('%g', scale*mean(results_map('radial-ag').(field_name))));
    template_str = strrep(template_str, '$$VALUE_RADIAL_AGS$$', sprintf('%g', scale*mean(results_map('radial-ags').(field_name))));
    
    % Y-axis specifier
    if is_percent
        template_str = strrep(template_str, '$$Y_AXIS_SPEC$$', 'ymin = 0, ymax = 100, ');
    else
        template_str = strrep(template_str, '$$Y_AXIS_SPEC$$', 'ymin = 0, ');
    end
    
    % Title string
    title_str = strrep(title_str, '%', '\%'); % Escape
    template_str = strrep(template_str, '$$TITLE_STRING$$', sprintf('\\textbf{%s}', title_str));
    
    % Save
    vicos.utils.ensure_path_exists(output_filename);
    fid = fopen(output_filename, 'w+');
    fwrite(fid, template_str);
    fclose(fid);
end

function output = process_results (results, use_unique)
    if ~exist('use_unique', 'var') || isempty(use_unique)
        use_unique = false;
    end
    
    % Precision: number of correct matches / number of putative matches
    if use_unique
        output.precision = [ results.num_correct_matches_unique ] ./ [ results.num_putative_matches_unique ];
    else
        output.precision = [ results.num_correct_matches ] ./ [ results.num_putative_matches ];
    end
    output.precision(~isfinite(output.precision)) = 0; % NaN, Inf -> 0

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

