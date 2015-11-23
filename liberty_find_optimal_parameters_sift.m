% LIBERTY_FIND_OPTIMAL_PARAMETERS_SIFT ()
% 
% Determines optimal parameters for SIFT descriptor (the scaling parameter
% for the patches).
function liberty_find_optimal_parameters_sift ()

    %% Settings
    settings.patch_scales = 1:20;
    settings.num_repetitions = 5;
    settings.num_patches = [ 500, 1000, 2000, 3000, 5000, 7000 ];

    %% Run the experiment
    settings.patch_scales = sort(settings.patch_scales);

    sift = vicos.descriptor.SIFT();
    result_file = 'liberty-scale-optimization-sift.mat';
    
    if ~exist(result_file, 'file'),
        results = evaluate_descriptor_extractor_parameters(sift, settings);
        
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
        
        h(n) = errorbar(settings.patch_scales, mean(data), std(data));
        hold on;
        
        legend_entries{n} = sprintf('#%d', settings.num_patches(n));
    end
    title('SIFT recognition rate on liberty');
    xlabel('Scale parameter');
    ylabel('Recognition rate [%]');
    ylim([0, 100]);
    xlim([settings.patch_scales(1), settings.patch_scales(end)]);
    grid on;
    legend(h, legend_entries);
end

function results = evaluate_descriptor_extractor_parameters (sift, settings)
    % Experiments...
    dataset = LibertyDataset();

    results = cell(1, numel(settings.num_patches));

    for n = 1:numel(settings.num_patches),
        num_patches = settings.num_patches(n);

        fprintf('Running experiment with %d patches...\n', num_patches);

        tmp_results = nan(settings.num_repetitions, numel(settings.patch_scales));

        for r = 1:settings.num_repetitions,
            fprintf(' Running repetition #%d...\n', r);
            [ patch_idx1, patch_idx2 ] = dataset.get_random_correspondence_set(num_patches);

            for p = 1:numel(settings.patch_scales),
                sift.patch_scale_factor = settings.patch_scales(p); % Change patch scale factor

                % Extract all desccriptors
                for d = num_patches:-1:1,
                    desc1(d,:) = sift.compute_from_patch(dataset.get_patch(patch_idx1(d)));
                    desc2(d,:) = sift.compute_from_patch(dataset.get_patch(patch_idx2(d)));
                end

                % Compute the distances
                dist = sift.compute_pairwise_distances(desc1, desc2);

                % Determine matches
                [ ~, midx ] = min(dist, [], 1);
                matches = midx == 1:numel(midx);

                tmp_results(r, p) = sum(matches) / numel(matches);
                fprintf(' > scale %.4f: %.2f %%\n', sift.patch_scale_factor, tmp_results(r, p)*100); 
            end
        end

        results{n} = tmp_results;
    end
end