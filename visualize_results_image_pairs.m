function fig = visualize_results_image_pairs (results)
     %% Compute mean and std
    recognition_rates_mean = squeeze( mean(results.recognition_rates) );
    recognition_rates_std = squeeze( std(results.recognition_rates) );
    
    %% Print
    for p = 1:size(results.recognition_rates, 3),
        fprintf('Pair: 1|%d\n', results.pairs(p));
        for d = 1:size(results.recognition_rates, 2),
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
    set(gca, 'XTickLabel', arrayfun(@(x) sprintf('1|%d', x), results.pairs', 'UniformOutput', false));
    xlabel('Image pair');
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
    
    title(results.title);
end