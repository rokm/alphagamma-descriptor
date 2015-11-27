function fig = visualize_results_rotation (results)
    % fig = VISUALIZE_RESULTS_ROTATION (results)
    %
    % Visualizes results of rotation batch experiments.
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
    num_angles = size(results.recognition_rates, 3);
    
     %% Compute mean and std
    recognition_rates_mean = mean(results.recognition_rates, 1);
    recognition_rates_std = std(results.recognition_rates, [], 1);
    
    recognition_rates_mean = reshape(recognition_rates_mean, num_descriptors, num_angles);
    recognition_rates_std = reshape(recognition_rates_std, num_descriptors, num_angles);
    
    %% Print
    for a = 1:num_angles,
        fprintf('Angle: %f deg\n', results.angles(a));
        for d = 1:num_descriptors,
            fprintf(' %s: %.2f +/- %.2f %%\n', results.descriptor_names{d}, recognition_rates_mean(d,a)*100, recognition_rates_std(d,a)*100);
        end
    end

    %% Plot
    fig = figure();

    h = nan(1, num_descriptors); 
    
    for d = 1:num_descriptors,
        h(d) = errorbar(results.angles, recognition_rates_mean(d,:), recognition_rates_std(d,:));
        hold on;
    end
    
    % Annotations
    grid on;
    xlabel('Angle [deg]');
    ylabel('Recognition rate [%]');
    ylim([0, 1]);
    if numel(results.angles) > 1,
        xlim([results.angles(1), results.angles(end)]);
    end
    legend(h, results.descriptor_names, 'Location', 'SouthWest');
    
    title(results.title, 'Interpreter', 'none');
end