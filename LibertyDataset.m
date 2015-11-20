classdef LibertyDataset < handle
    % LIBERTYDATASET - Liberty Dataset adapter
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        dataset_path
        
        patch_ids
        unique_patch_ids
       
        % Patch arrangements
        patches_per_row
        patches_per_image
        patch_size
        
        % Image caching
        cached_image_id = -1
        I
    end
    
    methods
        function self = LibertyDataset (varargin)
            parser = inputParser();
            parser.addParameter('dataset_path', '/home/rok/Projects/jasna/datasets/liberty', @ischar);
            parser.parse(varargin{:});
            
            % Dataset path
            self.dataset_path = parser.Results.dataset_path;
            assert(exist(self.dataset_path, 'dir') ~= 0, 'Non-existing dataset path');
            
            % Setup patch information
            self.patches_per_row = 16;
            self.patches_per_image = 16*16; % 16 times 16 patches
            self.patch_size = 64; % Patches are 64x64 pixels
            
            % Read and parse the info file
            fid = fopen( fullfile(self.dataset_path, 'info.txt') );
            data = textscan(fid, '%d %*d');
            fclose(fid);
            
            % Gather patch IDs
            self.patch_ids = data{1};
            self.unique_patch_ids = unique(self.patch_ids);
        end
        
        function [ patch_idx1, patch_idx2 ] = get_random_correspondence_set (self, num_patches)
            % [ patch_idx1, patch_idx2 ] = GET_RANDOM_CORRESPONDENCE_SET (self, num_patches)
            %
            % Generates two sets of corresponding image patches with
            % specified cardinality.
            %
            % In particular, a random set of patch ids is chosen. For each
            % selected patch id, two patches are chosen at random, and
            % placed in output sets.
            %
            % Input:
            %  - self: @LibertyDataset instance
            %  - num_patches: number of corresponding patches to select
            %
            % Output:
            %  - patch_idx1: indices of patches in the first set
            %  - patch_idx2: indices of corresponding patches in the second 
            %    set
            
            % Randomly select the desired number of patch IDs
            selected_ids = self.unique_patch_ids( randperm(numel(self.unique_patch_ids), num_patches) );
            
            selected_ids = sort(selected_ids); % Sort the IDs, so that we will end up with adjacent image accesses...
            
            patch_idx1 = nan(num_patches, 1);
            patch_idx2 = nan(num_patches, 1);
            
            for p = 1:num_patches,
                patch_id = selected_ids(p);
                
                patch_indices = find(self.patch_ids == patch_id);
                
                % Select two indices, one for the first set and one for the
                % second set
                selected_indices = patch_indices( randperm(numel(patch_indices), 2) );
                
                patch_idx1(p) = selected_indices(1);
                patch_idx2(p) = selected_indices(2);
            end
        end
        
        function I = get_patch (self, patch_idx)
            % I = GET_PATCH (self, patch_idx)
            %
            % Retrieves the specified patch from the dataset.
            %
            % Input:
            %  - self: @LibertyDataset instance
            %  - patch_id: 1-based index of the patch to retrieve (note
            %    that this is *not* the patch id, but rather its index in
            %    the dataset)
            %
            % Output:
            %  - I: the retrieved patch
            
            assert(patch_idx >= 1 && patch_idx <= numel(self.patch_ids), 'Patch index out of bounds!');
            
            % Convert from 1-based index to 0-based one, because it
            % simplifies the modulo-based computations
            patch_idx = patch_idx - 1;
            
            % Compute image index
            image_idx = floor(patch_idx / self.patches_per_image);
            
            % We improve the retrieval time by caching the image (assuming
            % that the patches are accessed in more or less sequential way)
            if image_idx ~= self.cached_image_id,
                image_file = fullfile(self.dataset_path, sprintf('patches%04d.bmp', image_idx));
                
                self.I = imread(image_file);
                self.cached_image_id = image_idx;
            end
            
            % Compute patch index in the image, and derive row and col
            % positions
            patch_idx = mod(patch_idx, self.patches_per_image);
            row_idx = floor(patch_idx/self.patches_per_row);
            col_idx = mod(patch_idx, self.patches_per_row);
            
            xmin = col_idx*self.patch_size + 1;
            xmax = xmin + self.patch_size - 1;
            
            ymin = row_idx*self.patch_size + 1;
            ymax = ymin + self.patch_size - 1;
            
            % Crop out the patch
            I = self.I(ymin:ymax, xmin:xmax, :);
        end
    end
end
        