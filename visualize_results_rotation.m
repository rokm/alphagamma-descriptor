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
    
    if isa(results, 'char'),
        results = load(results);
    end
    
     %% Compute mean and std
    recognition_rates_mean = squeeze( mean(results.recognition_rates) );
    recognition_rates_std = squeeze( std(results.recognition_rates) );
    
    %% Print
    for p = 1:size(results.recognition_rates, 3),
        fprintf('Angle: %f deg\n', results.angles(p));
        for d = 1:size(results.recognition_rates, 2),
            fprintf(' %s: %.2f +/- %.2f %%\n', results.descriptor_names{d}, recognition_rates_mean(d,p)*100, recognition_rates_std(d,p)*100);
        end
    end

    %% Plot
    fig = figure();

    h = nan(1, size(results.recognition_rates, 2)); 
    
    for d = 1:size(results.recognition_rates, 2),
        h(d) = errorbar(results.angles, recognition_rates_mean(d,:), recognition_rates_std(d,:));
        hold on;
    end
    
    % Annotations
    grid on;
    xlabel('Angle [deg]');
    ylabel('Recognition rate [%]');
    ylim([0, 1]);
    xlim([results.angles(1), results.angles(end)]);
    legend(h, results.descriptor_names, 'Location', 'SouthWest');
    
    title(results.title, 'Interpreter', 'none');
end