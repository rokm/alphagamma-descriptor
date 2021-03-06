classdef DeepDesc < vicos.descriptor.Descriptor
    % DEEPDESC - DeepDesc descriptor
    %
    % This class provides Matlab wrapper for Torch implementation of the
    % DeepDesc descriptor.
    %
    % E. Simo-Serra, E. Trulls, L. Ferraz, I. Kokkinos, P. Fua, and 
    % F. Moreno-Noguer. "Discriminative Learning of Deep Convolutional 
    % Feature Point Descriptors", International Conference on Computer 
    % Vision (ICCV), 2015
    %
    % (C) 2018, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>

    properties
        patch_extractor
        model_file
        lua_script
        
        batch_size
    end

    methods
        function self = DeepDesc (varargin)
            % self = DeepDesc (varargin)
            %
            % Creates DeepDesc descriptor extractor.
            %
            % Input: optional key/value pairs:
            %  - model_file: DeepDesc model file to use. Leave empty
            %    (default) to use CNN3_p8_n8_split4_073000.t7 file provided
            %    by the original source.
            %  - scale_factor: scale factor to enlarge the keypoint's area
            %    of interest (default: 5)
            %  - orientation_normalized: use keypoint-provided orientations
            %    to orientation-normalize patches before computing
            %    descriptors (default: false)
            %  - batch_size: batch size to avoid running out of memory
            %    (default: 1000)
            %
            % Output:
            %  - self:

            % Input parser
            parser = inputParser();
            parser.KeepUnmatched = true;
            parser.addParameter('model_file', '', @ischar);
            parser.addParameter('scale_factor', 5, @isnumeric);
            parser.addParameter('orientation_normalized', false, @isnumeric);
            parser.addParameter('batch_size', 1000, @isnumeric);
            parser.parse(varargin{:});

            self = self@vicos.descriptor.Descriptor(parser.Unmatched);

            self.model_file = parser.Results.model_file;
            self.batch_size = parser.Results.batch_size;
            
            % Create patch extractor
            scale_factor = parser.Results.scale_factor;
            orientation_normalized = parser.Results.orientation_normalized;
            
            self.patch_extractor = vicos.utils.PatchExtractor(...
                'scale_factor', scale_factor, ... % User-provided value
                'target_size', 64, ... % Torch code expects 64x64 patches
                'replicate_border', true, ... % Replicate border
                'normalize_orientation', orientation_normalized, ... % User-provided parameter
                'color_patches', false ... % Torch code expects single-channel patches
            );
        
            % Resolve the paths of DeepDesc code and models, and the lua
            % script
            root_dir = fileparts(mfilename('fullpath'));
            
            self.lua_script = fullfile(root_dir, 'run_deep_desc.lua');
            
            deepdesc_root = fullfile(root_dir, '..', '..', '..', 'external', 'deepdesc-release');
            if isempty(self.model_file)
                self.model_file = fullfile(deepdesc_root, 'models', 'CNN3_p8_n8_split4_073000.t7');
            end
        end

        function [ descriptors, keypoints ] = compute (self, I, keypoints)
            %% Use patch extractor to extract patches
            [ all_patches, keypoints ] = self.patch_extractor.extract_patches(I, keypoints);
            
            % Sanity check
            assert(size(all_patches, 1) == 64 && size(all_patches, 2) == 64 && size(all_patches, 3) == 1, 'Patches must be 64x64x1!');

            %% Prepare command
            % Temporary folder for data exchange
            tmp_dir = tempname();
            mkdir(tmp_dir);
            
            % Input and output file
            tmp_patch_file = fullfile(tmp_dir, 'patches.mat');
            tmp_desc_file = fullfile(tmp_dir, 'descriptors.mat');

            % Command
            command = sprintf('th "%s" --model "%s" --input "%s" --output "%s"', self.lua_script, self.model_file, tmp_patch_file, tmp_desc_file);
            
            %% Compute descriptors
            % Allocate descriptors
            descriptors = nan(numel(keypoints), self.get_descriptor_size(), 'single');
            
            num_descriptors = size(descriptors, 1);
            num_processed = 0;
            batch_size = self.batch_size;

            if ~isfinite(batch_size)
                batch_size = num_descriptors;
            end

            while num_processed < num_descriptors
                % Clamp batch size
                batch_size = min(batch_size, num_descriptors - num_processed);

                % Determine indices
                pos1 = num_processed + 1;
                pos2 = pos1 + batch_size - 1;
                
                % Save patches
                patches = all_patches(:,:,:,pos1:pos2);
                save(tmp_patch_file, 'patches', '-v7.3');
                
                % Run lua script
                [ status, result ] = system(command);
                
                % Check script status
                if status
                    error('Wrapper script failed! Output:\n%s\n', result);
                end
                
                % Read descriptors
                tmp = load(tmp_desc_file);
            
                % Convert descriptors from double-precision to single-precision
                % (because lua-side export supports only double-precision).
                % Also, transpose to Nx128 to be consistent with our framework.
                descriptors(pos1:pos2,:) = single(tmp.x');


                % Update the count
                num_processed = num_processed + batch_size;
            end

            %% Cleanup
            if true
                rmdir(tmp_dir, 's');
            end
        end

        function distances = compute_pairwise_distances (self, desc1, desc2)
            % Compute the distances using cv::batchDistance() and L2 norm;
            % in order to get an N2xN1 matrix, we switch desc1 and desc2
            distances = cv.batchDistance(desc2, desc1, 'K', 0, 'NormType', 'L2');
        end

        function descriptor_size = get_descriptor_size (self)
            % Fixed-size
            descriptor_size = 128; % 128 floating-point values
        end
    end

    methods (Access = protected)
        function identifier = get_identifier (self)
            identifier = 'DeepDesc';
        end
    end
end
