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
            %
            % Output:
            %  - self:

            % Input parser
            parser = inputParser();
            parser.KeepUnmatched = true;
            parser.addParameter('model_file', 5, @isnumeric);
            parser.addParameter('scale_factor', 5, @isnumeric);
            parser.parse(varargin{:});

            self = self@vicos.descriptor.Descriptor(parser.Unmatched);

            % Create patch extractor
            scale_factor = parser.Results.scale_factor;
            self.patch_extractor = vicos.utils.PatchExtractor(...
                'scale_factor', scale_factor, ... % Use user-provided scale factor
                'target_size', 64, ... % Torch code expects 64x64 patches
                'replicate_border', true, ... % Replicate border
                'normalize_orientation', false, ... % TODO: make this a parameter
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
            [ patches, keypoints ] = self.patch_extractor.extract_patches(I, keypoints);
            
            %% Temporary folder for data exchange
            tmp_dir = tempname();
            mkdir(tmp_dir);
            
            tmp_patch_file = fullfile(tmp_dir, 'patches.mat');
            tmp_desc_file = fullfile(tmp_dir, 'descriptors.mat');
            
            %% Save patches
            assert(size(patches, 1) == 64 && size(patches, 2) == 64 && size(patches, 3) == 1, 'Patches must be 64x64x1!');
            
            save(tmp_patch_file, 'patches', '-v7.3');
            
            %% Run lua script
            command = sprintf('th "%s" --model "%s" --input "%s" --output "%s"', self.lua_script, self.model_file, tmp_patch_file, tmp_desc_file);
            [ status, result ] = system(command);

            %% Check script status
            if status
                error('Wrapper script failed! Output:\n%s\n', result);
            end
            
            %% Read descriptors
            tmp = load(tmp_desc_file);
            
            % Convert descriptors from double-precision to single-precision
            % (because lua-side export supports only double-precision).
            % Also, transpose to Nx128 to be consistent with our framework.
            descriptors = single(tmp.x');
            
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
