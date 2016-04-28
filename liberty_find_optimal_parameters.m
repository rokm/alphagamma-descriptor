function fig = liberty_find_optimal_parameters (experiment_id)
    % fig = LIBERTY_FIND_OPTIMAL_PARAMETERS (experiment_id)
    %
    % Performs experiments on Liberty dataset with aim of producing results
    % across a wide range of parameters for a descriptor extractor (e.g., a
    % scale parameter). The descriptor extractor and the nature of the
    % parameters are encoded by experiment_id, which also serves as
    % identifier for results caching. The result of this function is a
    % recognition rate plot for several parameter values and for several
    % cardinalitites of the patch set.
    %
    % Input:
    %  - experiment_id: experiment id
    %
    % Output:
    %  - fig: handle of resulting figure
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    % Cache directory
    results_dir = 'results-liberty-parameters';
    results_file = fullfile(results_dir, sprintf('%s.mat', experiment_id));
    
    %% Load results or run the experiment
    if exist(results_file, 'file'),
        fprintf('Found a cache file! Loading results...\n');
        results = load(results_file);
    else
        % Global parameters
        num_repetitions = 5;
        num_patches = [ 500, 1000, 2000, 3000, 5000, 7000 ];
        
        % Experiment IDs
        switch experiment_id,
            case 'surf',
                parameter_field = 'patch_scale_factor';
                parameter_values = 1:20;
                parameter_description = 'Scale factor';
                experiment_title = 'SURF';
                
                descriptor_extractor = vicos.descriptor.SURF('HessianThreshold', 400, 'NOctaves', 3, 'NOctaveLayers', 4, 'Upright', true); % use OpenCV 2.3 options
            
            case 'sift',
                parameter_field = 'patch_scale_factor';
                parameter_values = 1:20;
                parameter_description = 'Scale factor';
                experiment_title = 'SIFT';
                
                descriptor_extractor = vicos.descriptor.SIFT();
                
            case 'brisk',
                parameter_field = 'patch_scale_factor';
                parameter_values = 0.1:0.025:0.3; % 0.3 is max before we keypoint gets dropped!
                parameter_description = 'Scale factor';
                experiment_title = 'BRISK';
                
                descriptor_extractor = vicos.descriptor.BRISK();
            
            case 'brief',
                parameter_field = 'patch_size';
                parameter_values = 58:8:116;
                parameter_description = 'Effective patch size';
                experiment_title = 'BRIEF';
                
                descriptor_extractor = vicos.descriptor.BRIEF('Bytes', 64);
            
            case 'latch',
                parameter_field = 'patch_size';
                parameter_values = 56:8:112;
                parameter_description = 'Effective patch size';
                experiment_title = 'LATCH';
                
                descriptor_extractor = vicos.descriptor.LATCH('Bytes', 64);
            
            case 'kaze',
                parameter_field = 'keypoint_size';
                parameter_values = 1:1:10;
                parameter_description = 'Keypoint size';
                experiment_title = 'KAZE';
                
                descriptor_extractor = vicos.descriptor.KAZE('Upright', false);
                
            case 'freak',
                parameter_field = 'keypoint_size';
                parameter_values = [ 5:1:9, 9.68 ]; % Max allowable value for stock FREAK is 9.68!
                parameter_description = 'Keypoint size';
                experiment_title = 'FREAK';
                
                descriptor_extractor = vicos.descriptor.FREAK('OrientationNormalized', false);
            
            %% AlphaGamma variants
            case 'ag-basic',
                parameter_field = 'effective_patch_size';
                parameter_values = (0.8:0.05:1.2)*95; % Base effective size: 95
                parameter_description = 'Effective patch size';
                experiment_title = 'AG-Basic';
                
                descriptor_extractor = vicos.descriptor.AlphaGamma('orientation', false, 'num_rays', 41, 'num_circles', 12, 'compute_extended', false, 'sampling', 'simple', 'use_scale', false, 'base_sigma', sqrt(2));

            case 'ag60',
                parameter_field = 'effective_patch_size';
                parameter_values = (0.8:0.05:1.2)*149; % Base effective size: 149
                parameter_description = 'Effective patch size';
                experiment_title = 'AG60';
                
                descriptor_extractor = vicos.descriptor.AlphaGamma('orientation', false, 'num_rays', 23, 'num_circles', 10, 'circle_step', 1.042*sqrt(2));
                
            case 'ag32',
                parameter_field = 'effective_patch_size';
                parameter_values = (0.8:0.05:1.2)*155; % Base effective size: 155
                parameter_description = 'Effective patch size';
                experiment_title = 'AG32';
                
                descriptor_extractor = vicos.descriptor.AlphaGamma('orientation', false, 'num_rays', 13, 'num_circles', 9, 'circle_step', 1.104*sqrt(2));

            otherwise,
                error('Invalid experiment ID: %s!', experiment_id);
        end
        
        % Obtain results
        results = liberty_evaluate_descriptor_extractor_parameters(descriptor_extractor, experiment_title, parameter_field, parameter_values, parameter_description, num_patches, num_repetitions);
        
        % Save
        if ~exist(results_dir, 'dir'),
            mkdir(results_dir);
        end
        save(results_file, '-struct', 'results');
    end
    
    %% Visualize
    fig = liberty_visualize_parameter_search_results(results);
end

function results = liberty_evaluate_descriptor_extractor_parameters (descriptor_extractor, experiment_title, parameter_field, parameter_values, parameter_description, patchset_sizes, num_repetitions)
    % results = LIBERTY_EVALUATE_DESCRIPTOR_EXTRACTOR_PARAMETERS (descriptor_extractor, experiment_title,, parameter_field, parameter_values, parameter_description, num_patches, num_repetitions)
    %
    % Performs experiments on the Liberty dataset with the given descriptor
    % extractor, and varies both number of selected patches and the
    % descriptor extractor's scale parameter, as specified by the provided
    % settings.
    %
    % Input:
    %  - descriptor_extractor: a vicos.descriptor.Descriptor instance
    %  - experiment_title: experiment title to display in the plot's title
    %  - parameter_field:
    %  - parameter_values
    %  - parameter_description
    %  - patchset_sizes:
    %  - num_repetitions
    %
    %  - varargin: key/value pairs specifying additional parameters:
    %     - num_repetitions: number of repetitions (default: 5)
    %     - num_patches: vector of patch set cardinalities to experiment
    %       with (default: [ 500, 1000, 2000, 3000, 5000, 7000 ])
    %     - param_field_name: parameter field name in the descriptor class
    %     - param_values: values of the parameter to test with
    %     - param_description: parameter description to display on
    %       horizontal axis of the plot
    
    % Create dataset
    dataset = LibertyDataset();
    
    % Copy settings
    results.experiment_title = experiment_title;
    results.parameter_field = parameter_field;
    results.parameter_values = parameter_values;
    results.parameter_description = parameter_description;
    results.patchset_sizes = patchset_sizes;
    results.num_repetitions = num_repetitions;
    
    % Recognition rates
    recognition_rate = nan(num_repetitions, numel(parameter_values), numel(patchset_sizes));

    fprintf('--- Experiment: %s ---\n', experiment_title);
    for n = 1:numel(patchset_sizes),
        num_patches = patchset_sizes(n);
        
        fprintf('Running with %d patches...\n', num_patches);

        for r = 1:num_repetitions,
            fprintf(' Running repetition #%d/%d...\n', r, num_repetitions);
            
            % Get random patch correspondence set with desired cardinality
            [ patch_idx1, patch_idx2 ] = dataset.get_random_correspondence_set(num_patches);

            for p = 1:numel(parameter_values),
                % Change the parameter value in descriptor extractor
                descriptor_extractor.(parameter_field) = parameter_values(p);

                % Extract all descriptors
                for d = num_patches:-1:1,
                    desc1(d,:) = descriptor_extractor.compute_from_patch(dataset.get_patch(patch_idx1(d)));
                    desc2(d,:) = descriptor_extractor.compute_from_patch(dataset.get_patch(patch_idx2(d)));
                end

                % Compute the distances
                dist = descriptor_extractor.compute_pairwise_distances(desc1, desc2);

                % Determine matches
                [ ~, midx ] = min(dist, [], 1);
                matches = midx == 1:numel(midx);

                % Compute recognition rate
                recognition_rate(r, p, n) = sum(matches) / numel(matches);
                fprintf(' > %s: %.4f -> %.2f %%\n', parameter_description, parameter_values(p), 100*recognition_rate(r, p, n)); 
            end
        end
    end
    
    results.recognition_rate = recognition_rate;
end
