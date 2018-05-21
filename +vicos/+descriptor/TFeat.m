classdef TFeat < vicos.descriptor.Descriptor
    % TFeat - TFeat descriptor
    %
    % This class provides Matlab wrapper for Caffe implementation of the
    % TFeat descriptor.
    %
    % V. Balntas, E. Riba, D. Ponsa, and K. Mikolajczyk. "Learning local 
    % feature descriptors with triplets and shallow convolutional neural 
    % networks.", BMVC 2016
    %
    % (C) 2018, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>

    properties
        net
        
        patch_extractor
        
        batch_size
    end

    methods
        function self = TFeat (varargin)
            % self = TFeat (varargin)
            %
            % Creates TFeat descriptor extractor.
            %
            % Input: optional key/value pairs:
            %  - proto_file: model's proto file. Leave empty (default) to
            %    use the one provided by the original source.
            %  - weights_file: model's weights file. Leave empty (default)
            %    to use the one provided by the original source.
            %  - use_gpu: whether to use GPU (default) or not. Note that
            %    the constructor calls caffe.set_gpu_mode() or
            %    caffe.set_cpu_mode() accordingly (so mode may be affected 
            %    by any manual subsequent calls to the said functions).
            %  - scale_factor: scale factor to enlarge the keypoint's area
            %    of interest (default: 5)
            %  - orientation_normalized: use keypoint-provided orientations
            %    to orientation-normalize patches before computing
            %    descriptors (default: false)
            %  - batch_size: batch size to avoid running out of memory
            %    (default: 1024)
            %
            % Output:
            %  - self:

            % Input parser
            parser = inputParser();
            parser.KeepUnmatched = true;
            parser.addParameter('proto_file', '', @ischar);
            parser.addParameter('weights_file', '', @ischar);
            parser.addParameter('use_gpu', true, @islogical);
            parser.addParameter('scale_factor', 5, @isnumeric);
            parser.addParameter('orientation_normalized', false, @isnumeric);
            parser.addParameter('batch_size', 1024, @isnumeric);
            parser.parse(varargin{:});

            self = self@vicos.descriptor.Descriptor(parser.Unmatched);

            self.batch_size = parser.Results.batch_size;
            
            % GPU vs CPU mode
            if parser.Results.use_gpu
                caffe.set_mode_gpu();
            else
                caffe.set_mode_cpu();
            end
            
            % Default TFeat directory
            root_dir = fileparts(mfilename('fullpath'));
            tfeat_dir = fullfile(root_dir, '..', '..', 'external', 'tfeat');
            
            % Proto file
            proto_file = parser.Results.proto_file;
            if isempty(proto_file)
                proto_file = fullfile(tfeat_dir, 'caffe', 'TFeatLiberty.prototxt');
            end
            
            % Weights file
            weights_file = parser.Results.weights_file;
            if isempty(weights_file)
                weights_file = fullfile(tfeat_dir, 'caffe', 'TFeatLiberty.caffemodel');
            end
            
            assert(exist(proto_file, 'file') ~= 0, 'Invalid proto file: %s!', proto_file);
            assert(exist(weights_file, 'file') ~= 0, 'Invalid weights file: %s!', weights_file);
            
            % Load network
            self.net = caffe.get_net(proto_file, weights_file, 'test');
            
            % Create patch extractor
            scale_factor = parser.Results.scale_factor;
            orientation_normalized = parser.Results.orientation_normalized;
            
            self.patch_extractor = vicos.utils.PatchExtractor(...
                'scale_factor', scale_factor, ... % User-provided value
                'target_size', 32, ... % Model expects 32x32 patches
                'replicate_border', true, ... % Replicate border
                'normalize_orientation', orientation_normalized, ... % User-provided parameter
                'color_patches', false, ... % Model expects single-channel patches
                'transpose_patches', true, ... % We need to transpose patches to match row-major layout
                'opencv_resize', false ... % Enable this for easier comparison with bundled python-based example
            );
        end

        function [ descriptors, keypoints ] = compute (self, I, keypoints)
            %% Use patch extractor to extract patches
            [ all_patches, keypoints ] = self.patch_extractor.extract_patches(I, keypoints);
            
            % Sanity check
            assert(size(all_patches, 1) == 32 && size(all_patches, 2) == 32 && size(all_patches, 3) == 1, 'Patches must be 32x32x1!');

            
            %% Process all batches
            num_patches = size(all_patches, 4);
            num_batches = ceil(num_patches/ self.batch_size);

            descriptors = nan(num_patches, self.get_descriptor_size(), 'single');

            idx = 1;
            for b = 1:num_batches
                cur_batch_size = min(num_patches, self.batch_size);

                fprintf('Batch #%d: %d patches (%d ~ %d)\n', b, cur_batch_size, idx, idx+cur_batch_size-1);

                % Process a batch
                patches = all_patches(:,:,:,idx:idx+cur_batch_size-1);

                self.net.blobs('data').reshape([ 32, 32, 1, cur_batch_size ]);
                self.net.blobs('data').set_data(patches);

                self.net.forward_prefilled();

                desc = self.net.blobs('tanh3').get_data();

                descriptors(idx:idx+cur_batch_size-1,:) = desc';

                idx = idx + cur_batch_size;
                num_patches = num_patches - cur_batch_size;
            end

            assert(num_patches == 0, 'Bug in code!');
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
            identifier = 'TFeat';
        end
    end
end
