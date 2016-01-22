function fig = visualize_results_image_pairs (results)
    % fig = VISUALIZE_RESULTS_IMAGE_PAIRS (results)
    %
    % Visualizes results of image-pair batch experiments.
    %
    % Input:
    %  - results: results structure or .mat filename
    %
    % Output:
    %  - fig: figure with visualization
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    if ischar(results),
        results = load(results);
    end
    
    num_repetitions = size(results.recognition_rates, 1);
    num_descriptors = size(results.recognition_rates, 2);
    num_pairs = size(results.recognition_rates, 3);

     %% Compute mean and std
    recognition_rates_mean = mean(results.recognition_rates, 1);
    recognition_rates_std = std(results.recognition_rates, [], 1);
    
    recognition_rates_mean = reshape(recognition_rates_mean, num_descriptors, num_pairs);
    recognition_rates_std = reshape(recognition_rates_std, num_descriptors, num_pairs);
    
    %% Print
    for p = 1:num_pairs,
        num_correspondences = min(results.num_requested_correspondences, results.num_established_correspondences(p));
        fprintf('Pair: 1|%d (%d correspondences)\n', results.pairs(p), num_correspondences);
        for d = 1:num_descriptors,
            fprintf(' %s: %.2f +/- %.2f %%\n', results.descriptor_names{d}, recognition_rates_mean(d,p)*100, recognition_rates_std(d,p)*100);
        end
    end

    %% Plot
    fig = figure();

    % Bar plot
    bar(recognition_rates_mean');
    hold on;

    % Annotations
    set(gca,'YGrid','on');
    xlabels = cell(numel(results.pairs), 1);
    for i = 1:numel(xlabels),
        num_text = sprintf('%d|%d', 1, results.pairs(i));
        corr_text = sprintf('(%d)', results.num_established_correspondences(i));
        xlabels{i} = sprintf('%*s\\newline%s', numel(corr_text), num_text, corr_text);
    end
    set(gca, 'XTickLabel', xlabels);
    xlabel('Image pair (num. correspondences)');
    ylabel('Recognition rate [%]');
    ylim([0, 1]);
    legend(results.descriptor_names);

    % Error bars
    num_groups = size(recognition_rates_mean, 2);
    num_bars = size(recognition_rates_mean, 1); 
    group_width = min(0.8, num_bars/(num_bars+1.5));

    for i = 1:num_bars,
        x = (1:num_groups) - group_width/2 + (2*i-1) * group_width / (2*num_bars);  % Aligning error bar with individual bar
        errorbar(x, recognition_rates_mean(i,:), recognition_rates_std(i,:), 'k', 'LineWidth', 1.5, 'LineStyle', 'none');
    end
    
    title(results.title, 'Interpreter', 'none');
    drawnow();
end