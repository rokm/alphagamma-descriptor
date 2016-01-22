function fig = visualize_results_scale (results)
    % fig = VISUALIZE_RESULTS_SCALE (results)
    %
    % Visualizes results of scale batch experiments.
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
    num_scales = size(results.recognition_rates, 3);
    
     %% Compute mean and std
    recognition_rates_mean = mean(results.recognition_rates, 1);
    recognition_rates_std = std(results.recognition_rates, [], 1);
    
    recognition_rates_mean = reshape(recognition_rates_mean, num_descriptors, num_scales);
    recognition_rates_std = reshape(recognition_rates_std, num_descriptors, num_scales);
    
    %% Print
    for s = 1:num_scales,
        num_correspondences = min(results.num_requested_correspondences, results.num_established_correspondences(s));
        fprintf('Scale: %f deg (%d correspondences)\n', results.scales(s), num_correspondences);
        for d = 1:num_descriptors,
            fprintf(' %s: %.2f +/- %.2f %%\n', results.descriptor_names{d}, recognition_rates_mean(d,s)*100, recognition_rates_std(d,s)*100);
        end
    end

    %% Plot
    fig = figure();

    h = nan(1, num_descriptors); 
    
    for d = 1:num_descriptors,
        h(d) = errorbar(results.scales, recognition_rates_mean(d,:), recognition_rates_std(d,:));
        hold on;
    end
    
    % Annotations
    grid on;
    xlabel('Scale factor');
    ylabel('Recognition rate [%]');
    ylim([0, 1]);
    if numel(results.scales) > 1,
        xlim([results.scales(1), results.scales(end)]);
    end
    legend(h, results.descriptor_names, 'Location', 'SouthWest');
    
    title(results.title, 'Interpreter', 'none');
    drawnow();
end