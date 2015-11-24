% LIBERTY_FIND_OPTIMAL_PARAMETERS_BRIEF ()
% 
% Determines optimal parameters for BRIEF descriptor (the effective patch
% size).
function liberty_find_optimal_parameters_brief ()

    %% Settings
    settings.patch_sizes = 58:2:76;
    settings.num_repetitions = 5;
    settings.num_patches = [ 500, 1000, 2000, 3000, 5000, 7000 ];

    %% Run the experiment
    settings.patch_sizes = sort(settings.patch_sizes);

    brief = vicos.descriptor.BRIEF('Bytes', 64);
    result_file = 'liberty-scale-optimization-brief.mat';
    
    if ~exist(result_file, 'file'),
        results = evaluate_descriptor_extractor_parameters(brief, settings);
        
        % Save
        save(result_file, 'settings', 'results');
    else
        fprintf('Result file already exists; loading...\n');
        load(result_file);
    end
    
    %% Plot
    legend_entries = cell(1, numel(settings.num_patches));
    h = nan(1, numel(settings.num_patches));
    
    figure;
    for n = 1:numel(settings.num_patches),
        data = results{n} * 100; % Convert to %
        
        h(n) = errorbar(settings.patch_sizes, mean(data), std(data));
        hold on;
        
        legend_entries{n} = sprintf('#%d', settings.num_patches(n));
    end
    title('BRIEF-64 recognition rate on liberty');
    xlabel('Effective patch size');
    ylabel('Recognition rate [%]');
    ylim([0, 100]);
    xlim([settings.patch_sizes(1), settings.patch_sizes(end)]);
    grid on;
    legend(h, legend_entries);
end

function results = evaluate_descriptor_extractor_parameters (brief, settings)
    % Experiments...
    dataset = LibertyDataset();

    results = cell(1, numel(settings.num_patches));

    for n = 1:numel(settings.num_patches),
        num_patches = settings.num_patches(n);

        fprintf('Running experiment with %d patches...\n', num_patches);

        tmp_results = nan(settings.num_repetitions, numel(settings.patch_sizes));

        for r = 1:settings.num_repetitions,
            fprintf(' Running repetition #%d...\n', r);
            [ patch_idx1, patch_idx2 ] = dataset.get_random_correspondence_set(num_patches);

            for p = 1:numel(settings.patch_sizes),
                brief.patch_size = settings.patch_sizes(p); % Change effective patch size

                % Extract all desccriptors
                for d = num_patches:-1:1,
                    desc1(d,:) = brief.compute_from_patch(dataset.get_patch(patch_idx1(d)));
                    desc2(d,:) = brief.compute_from_patch(dataset.get_patch(patch_idx2(d)));
                end

                % Compute the distances
                dist = brief.compute_pairwise_distances(desc1, desc2);

                % Determine matches
                [ ~, midx ] = min(dist, [], 1);
                matches = midx == 1:numel(midx);

                tmp_results(r, p) = sum(matches) / numel(matches);
                fprintf(' > size %.4f: %.2f %%\n', brief.patch_size, tmp_results(r, p)*100); 
            end
        end

        results{n} = tmp_results;
    end
end