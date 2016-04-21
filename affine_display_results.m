function fig = affine_display_results (results, varargin)
    % fig = AFFINE_DISPLAY_RESULTS (results, varargin)
    %
    % Visualizes results of affine-dataset batch experiments.
    %
    % Input:
    %  - results: results structure or .mat filename. If empty array is
    %    given instead, the file selection dialog will be shown to pick the
    %    results .mat file.
    %  - varargin: optional key/value pairs
    %     - display_variance: display variance, if available (default:
    %       true)
    %
    % Output:
    %  - fig: figure with visualization
    %
    % (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    parser = inputParser;
    parser.addParameter('display_variance', true, @islogical);
    parser.parse(varargin{:});
    
    display_variance = parser.Results.display_variance;
    
    % Load results
    if ~exist('results', 'var') || isempty(results),
        [ filename, pathname ] = uigetfile('*.mat', 'Pick a results file', 'MultiSelect', 'on');
        if isequal(filename, 0),
            return;
        end
        
        fig = cell(1, numel(filename));
        for p = 1:numel(filename),
            results = fullfile(pathname, filename{p});
            fig{p} = affine_display_results(results, varargin{:});
        end
        
        return;
    end
    
    if ischar(results),
        results = load(results);
    end
    
    num_repetitions = size(results.recognition_rates, 1);
    num_descriptors = size(results.recognition_rates, 2);
    num_values = size(results.recognition_rates, 3);
   
    % Sanity check
    assert(num_values == numel(results.values), 'Inconsistent results dimension!');
    assert(num_descriptors == numel(results.experiment.descriptors), 'Inconsistent results dimension!');

    descriptor_names = { results.experiment.descriptors.name };

    %% Compute mean and std
    recognition_rates_mean = mean(results.recognition_rates, 1);
    recognition_rates_std = std(results.recognition_rates, [], 1);
    
    recognition_rates_mean = reshape(recognition_rates_mean, num_descriptors, num_values);
    recognition_rates_std = reshape(recognition_rates_std, num_descriptors, num_values);
    
    %% Print
    for i = 1:num_values,
        num_correspondences = min(results.num_requested_correspondences, results.num_established_correspondences(i));
        
        switch results.type,
            case 'pairs',
                fprintf('Pair: %d|%d (%d correspondences)\n', results.base_image, results.values(i), num_correspondences);
            case 'rotation',
                fprintf('Angle: %f deg (%d correspondences)\n', results.values(i), num_correspondences);
            case 'scale',
                fprintf('Scale: %f (%d correspondences)\n', results.values(i), num_correspondences);
            case 'shear',
                fprintf('Shear: %f (%d correspondences)\n', results.values(i), num_correspondences);
        end

        for d = 1:num_descriptors,
            fprintf(' %s: %.2f +/- %.2f %%\n', descriptor_names{d}, recognition_rates_mean(d,i)*100, recognition_rates_std(d,i)*100);
        end
    end

    %% Plot
    fig = figure();
    
    if isequal(results.type, 'pairs'),
        %% Image pairs: bar plot with error bars
        
        % Bar plot
        h = bar(recognition_rates_mean');
        hold on;

        % Annotations
        set(gca,'YGrid','on');
        xlabels = cell(numel(results.values), 1);
        for i = 1:numel(xlabels),
            num_text = sprintf('%d|%d', 1, results.values(i));
            corr_text = sprintf('(%d)', results.num_established_correspondences(i));
            xlabels{i} = sprintf('%*s\\newline%s', numel(corr_text), num_text, corr_text);
        end
        set(gca, 'XTickLabel', xlabels);
        xlabel('Image pair (num. correspondences)');

        % Error bars (only if variance is available and turned on)
        if num_repetitions > 1 && display_variance,
            num_groups = size(recognition_rates_mean, 2);
            num_bars = size(recognition_rates_mean, 1); 
            group_width = min(0.8, num_bars/(num_bars+1.5));

            for i = 1:num_bars,
                x = (1:num_groups) - group_width/2 + (2*i-1) * group_width / (2*num_bars);  % Aligning error bar with individual bar
                errorbar(x, recognition_rates_mean(i,:), recognition_rates_std(i,:), 'k', 'LineWidth', 1.5, 'LineStyle', 'none');
            end
        end
    else
        %% Rotation, scale, shear: line plot with error bars
        h = nan(1, num_descriptors);
            
        if num_repetitions > 1 && display_variance,
            % Draw erorr-bar plots
            h = errorbar(repmat(results.values, num_descriptors, 1)' , recognition_rates_mean', recognition_rates_std');
        else
            % Draw regular plots
            h = plot(results.values, recognition_rates_mean);
        end

        % Annotations
        grid on;
        if numel(results.values) > 1,
            xlim([results.values(1), results.values(end)]);
        end
        
        switch results.type,
            case 'rotation',
                xlabel('Angle [deg]');
            case 'scale',
                xlabel('Scale factor');
            case 'shear',
                xlabel('Shear factor');
        end
    end
    
    ylabel('Recognition rate [%]');
    ylim([0, 1]);
    legend(h, descriptor_names);
    
    title(sprintf('%s - %s', results.sequence, results.experiment.title), 'Interpreter', 'none');
    drawnow();
end