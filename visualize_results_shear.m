function fig = visualize_results_shear (results)
    % fig = VISUALIZE_RESULTS_SHEAR (results)
    %
    % Visualizes results of shaer batch experiments.
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
    num_shear_values = size(results.recognition_rates, 3);

     %% Compute mean and std
    recognition_rates_mean = mean(results.recognition_rates, 1);
    recognition_rates_std = std(results.recognition_rates, [], 1);

    recognition_rates_mean = reshape(recognition_rates_mean, num_descriptors, num_shear_values);
    recognition_rates_std = reshape(recognition_rates_std, num_descriptors, num_shear_values);

    %% Print
    for a = 1:num_shear_values,
        num_correspondences = min(results.num_requested_correspondences, results.num_established_correspondences(a));
        fprintf('Shear: %f (%d correspondences)\n', results.shear_values(a), num_correspondences);
        for d = 1:num_descriptors,
            fprintf(' %s: %.2f +/- %.2f %%\n', results.descriptor_names{d}, recognition_rates_mean(d,a)*100, recognition_rates_std(d,a)*100);
        end
    end

    %% Plot
    fig = figure();

    h = nan(1, num_descriptors);

    for d = 1:num_descriptors,
        h(d) = errorbar(results.shear_values, recognition_rates_mean(d,:), recognition_rates_std(d,:));
        hold on;
    end

    % Annotations
    grid on;
    xlabel('Angle [deg]');
    ylabel('Recognition rate [%]');
    ylim([0, 1]);
    if numel(results.shear_values) > 1,
        xlim([results.shear_values(1), results.shear_values(end)]);
    end
    legend(h, results.descriptor_names, 'Location', 'SouthWest');

    title(results.title, 'Interpreter', 'none');
    drawnow();
end
