classdef AlphaGamma < vicos.descriptor.Descriptor
    % ALPHAGAMMA - AlphaGamma descriptor (Matlab version)
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>

    properties
        num_circles
        num_rays
        
        base_sigma
        circle_step
        
        threshold_alpha
        threshold_gamma

        % Non-binarized
        non_binarized_descriptor
        
        % Scale normalization
        scale_normalized
        base_keypoint_size % Base keypoint size normalization factor
        
        % Orientation normalization
        orientation_normalized
        
        % Pre-computed stuff
        radii
        sigmas
        filters

        bilinear_sampling
        
        % Distance function weights
        A
        G
        
        %
        use_bitstrings
    end

    % Helpers that create descriptors with parametrization from the paper
    methods (Static)
        function self = create_ag_float (varargin)
            % self = CREATE_AG_FLOAT (varargin)
            %
            % Creates a floating-point AG descriptor with parameters
            % corresponding to those used in the paper. Parameters can be
            % overriden similarly as when using the AlphaGamma constructor.
            %
            % NOTE: by default, scale normalization is enabled, but with
            % default base_keypoint_size; to use the descriptor with a
            % specific keypoint detector, base keypoint size may need to be
            % adjusted...
            self = vicos.descriptor.AlphaGamma('identifier', 'AG', ...
                'orientation_normalized', true, ...
                'scale_normalized', true, ...
                'bilinear_sampling', true, ...
                'use_bitstrings', true, ...
                'non_binarized_descriptor', true, ...
                'num_rays', 13, ...
                'num_circles', 9, ...
                'circle_step', sqrt(2)*1.104, ...
                varargin{:});
        end
        
        function self = create_ag_short (varargin)
            % self = CREATE_AG_SHORT (varargin)
            %
            % Creates a binarized AGS descriptor with parameters
            % corresponding to those used in the paper.  Parameters can be
            % overriden similarly as when using the AlphaGamma constructor.
            %
            % NOTE: by default, scale normalization is enabled, but with
            % default base_keypoint_size; to use the descriptor with a
            % specific keypoint detector, base keypoint size may need to be
            % adjusted...
            self = vicos.descriptor.AlphaGamma('identifier', 'AGS', ...
                'orientation_normalized', true, ...
                'scale_normalized', true, ...
                'bilinear_sampling', true, ...
                'use_bitstrings', true, ...
                'non_binarized_descriptor', false, ...
                'num_rays', 23, ...
                'num_circles', 10, ...
                'circle_step', sqrt(2)*1.042, ...
                varargin{:});
        end
    end
    
    % vicos.descriptor.Descriptor implementation
    methods
        function self = AlphaGamma (varargin)
            % self = ALPHAGAMMA (varargin)
            %
            % Construct AlphaGamma descriptor extractor.
            %
            % Input: key/value pairs:
            %  - num_circles: number of circles; default: 9
            %  - num_rays: number of rays; default: 13
            %  - circle_step: spacing between two circles; 
            %    default: sqrt(2)*1.104
            %  - base_sigma: sigma for DoG filter of the base image;
            %    default: sqrt(1.7)
            %  - orientation_normalized: normalize w.r.t. keypoint
            %    orientation (default: true). The orientation needs to be
            %    provided by keypoint detector.
            %  - scale_normalized: whether to use keypoint's size parameter
            %    to extract descriptor from size-normalized patch;
            %    otherwise, descriptor is extracted from fixed-size region.
            %    Default: true
            %  - base_keypoint_size: base factor when converting keypoint
            %    size to patch size; default: 18.5
            %  - bilinear sampling: bilinear sampling of points. Default:
            %    true
            %  - non_binarized_descriptor: whether to compute binarized
            %    descriptor or floating-point descriptor. Default: false
            %    (compute floating-point descriptor)
            % - threshold_alpha: threshold value for alpha part of
            %   binarized descriptor. Default: [] (compute from number of
            %   circles)
            % - threshold_gamma: threshold value for gamma part of
            %   binarized descriptor. Default: [] (compute from number of
            %   rays)
            % - A: distance weight for alpha part of binarized descriptor.
            %   Default: 5
            % - G: distance weight for gamma part of binarized descriptor.
            %   Default: 1
            % - use_bitstrings: store binarized descriptor as bitstrings
            %   (instead of byte). Default: true
            %
            % Output:
            %  - self: @AlphaGamma instance

            % Input parameters
            parser = inputParser();
            parser.KeepUnmatched = true;            

            parser.addParameter('num_circles', 9, @isscalar);
            parser.addParameter('num_rays', 13, @isscalar);
            parser.addParameter('circle_step', sqrt(2)*1.104, @isscalar);
            parser.addParameter('base_sigma', sqrt(1.7), @isnumeric);

            parser.addParameter('orientation_normalized', true, @islogical);
            
            parser.addParameter('scale_normalized', true, @islogical);
            parser.addParameter('base_keypoint_size', 18.5, @isnumeric);

            parser.addParameter('bilinear_sampling', true, @islogical);
            parser.addParameter('non_binarized_descriptor', true, @islogical);
            
            parser.addParameter('threshold_alpha', [], @isnumeric); % compute from LUT for num_circles-1!
            parser.addParameter('threshold_gamma', [], @isnumeric);
            parser.addParameter('A', 5.0, @isnumeric);
            parser.addParameter('G', 1.0, @isnumeric);
            parser.addParameter('use_bitstrings', true, @islogical);

            parser.addParameter('custom_radii', [], @isnumeric);
            parser.addParameter('custom_sigmas', [], @isnumeric);
            
            parser.parse(varargin{:});
            
            self = self@vicos.descriptor.Descriptor(parser.Unmatched);

            self.num_circles = parser.Results.num_circles;
            self.num_rays = parser.Results.num_rays;
            self.circle_step = parser.Results.circle_step;
            self.base_sigma = parser.Results.base_sigma;
            
            self.orientation_normalized = parser.Results.orientation_normalized;
                        
            self.scale_normalized = parser.Results.scale_normalized;
            self.base_keypoint_size = parser.Results.base_keypoint_size;
            
            self.bilinear_sampling = parser.Results.bilinear_sampling;
            self.non_binarized_descriptor = parser.Results.non_binarized_descriptor;
            
            self.threshold_alpha = parser.Results.threshold_alpha;
            self.threshold_gamma = parser.Results.threshold_gamma;
            self.A = parser.Results.A;
            self.G = parser.Results.G;
            self.use_bitstrings = parser.Results.use_bitstrings;
                                    
            % Determine thresholds as the inverse of Student's T CDF with
            % number of elements in alpha or gamma (minus 1) as degrees of
            % freedom, and 50% confidence interval
            if isempty(self.threshold_alpha)
                dof = self.num_circles - 1;
                self.threshold_alpha = tinv(1 - 0.5/2, dof);
            end
            if isempty(self.threshold_gamma)
                % Per-column gamma variances
                dof = self.num_rays - 1;
                self.threshold_gamma = tinv(1 - 0.5/2, dof);
            end
            
            %% Set radii and sigmas
            sigmas = parser.Results.custom_sigmas;
            radii = parser.Results.custom_radii;
            
            assert(isempty(sigmas) == isempty(radii), 'Both or neither custom radii and sigmas need to be provided!');
            
            if ~isempty(sigmas)
                % Validate given parameters
                assert(nume(sigmas) == self.num_circles, 'Number of elements in custom sigmas vector must match number of circles!');
                assert(nume(sigmas) == self.num_circles, 'Number of elements in custom sigmas vector must match number of circles!');
            else
                % Compute radii and sigmas
                sigmas = zeros(self.num_circles, 1);
                radii = zeros(self.num_circles, 1);
            end
            
            
            %% Pre-compute filters
            
            self.filters = cell(self.num_circles, 1);

            % Filter parameters (radius and sigma)
            step = self.circle_step;
            for i = 1:self.num_circles
                if i == 1
                    sigmas(i) = 0.3; % Variable
                    radii(i) = 0.71/0.3 * sigmas(i);
                else
                    sigmas(i) = sigmas(i-1)*step;
                    radii(i) = radii(i-1) + step*sigmas(i);
                end
            end

            radii(1) = 0; % Set first radius to 0 (= center)
    
            self.radii = radii;
            self.sigmas = sigmas;
                        
            % Compute filters
            for i = 1:self.num_circles
                if self.sigmas(i) <= 0.7
                    continue;
                end
                
                self.filters{i} = create_gaussian_filter(sigmas(i));
            end
        end

        function [ desc, keypoints ] = compute (self, I, keypoints)

            % NOTE: keypoints' coordinates are zero-based as we use OpenCV
            % convention; therefore, we need to convert them to 1-based
            % indices (and round them) - this is done below, when calling
            % extract_descriptor_from_keypoint()
            
            % Convert to grayscale
            if size(I, 3) == 3
                I = rgb2gray(I);
            end

            % Filter out keypoints that are too close to the image border
            % (disabled, because we now clamp the sampling points inside
            % the valid region)
            %keypoints = self.filter_keypoints(I, keypoints);
            
            num_points = numel(keypoints);

            if self.non_binarized_descriptor
                % Real-valued version
                desc = zeros(get_descriptor_size(self), num_points, 'double');
            else
                % Binary version
                desc = zeros(get_descriptor_size(self), num_points, 'uint8');
            end
            
            %% Single-scale version
            if ~self.scale_normalized
                responses = self.compute_filter_responses(I);
            
                for p = 1:num_points
                    % Extract each point from the first-level of responses
                    % pyramid (which is also the only one we have). Note 
                    % the 0-based to 1-based coordinate system conversion
                    desc(:,p) = extract_descriptor_from_keypoint(self, responses, keypoints(p).pt + 1, 1.0, keypoints(p).angle); 
                end
            else
                %% Multi-scale version
                num_octaves = 6;
                
                % Construct pyramid of image response maps
                responses = cell(1, num_octaves);
                
                % Option 1: Resizing of filtered images
                responses{1} = self.compute_filter_responses(imresize(I,2));
                for i = 2:num_octaves
                    factor = 0.5^(i-1);
                    responses{i} = imresize(responses{1}, factor);
                end
                
                % Process all keypoints
                for p = 1:num_points
                    keypoint = keypoints(p);
                    
                    % Determine octave and scale factors
                    normalized_size = keypoint.size / self.base_keypoint_size;
                    
                    if normalized_size <= 1.75
                       octave = 1; % 1x upsampled image
                    elseif normalized_size <= 2*1.75
                        octave = 2; % Original image
                    elseif normalized_size <= 4*1.75
                        octave = 3; % 1x downsampled image
                    elseif normalized_size <= 8*1.75
                        octave = 4; % 2x downsampled image
                    elseif normalized_size <= 16*1.75
                        octave = 5; % 3x downsampled image
                    elseif normalized_size <= 32*1.75
                        octave = 6; % 4x downsampled image
                    else
                        octave = 6; % Same for the rest
                    end
                    
                    % Scale the keypoint's center
                    new_center = keypoint.pt - 0.5*(1-2^(octave-2)) + 1;
                    new_center = new_center * 0.5^(octave - 2);
                    
                    % Scale factor for the radii
                    scale_factor = keypoint.size*2/(self.base_keypoint_size * 2^(octave-1));
                    
                    % Extract
                    desc(:,p) = extract_descriptor_from_keypoint(self, responses{octave}, new_center, scale_factor, keypoint.angle);
                end
            end
            
            % Transpose the descriptor to get MxD matrix
            desc = desc';
        end
        
        function response_maps = compute_filter_responses (self, I)
            % pyramid = COMPUTE_FILTER_RESPONSES (self, I)
            %
            % Computes the stack of filter response maps. Each filter
            % corresponds to a sampling circle radius, hence the output is
            % HxWxM, with M being the number of sampling circles.
            
            response_maps = zeros(size(I, 1), size(I, 2), self.num_circles);
            
            if self.base_sigma ~= 0
                response_maps(:,:,1) = filter2(create_gaussian_filter(self.base_sigma), I);
            else
                response_maps(:,:,1) = I;
            end
            
            for i = 2:self.num_circles
                if isempty(self.filters{i})
                    response_maps(:,:,i) = response_maps(:,:,i-1);
                else
                    response_maps(:,:,i) = filter2(self.filters{i}, response_maps(:,:,1));
                end
            end
        end

        function distances = compute_pairwise_distances (self, desc1, desc2)
            % distances = COMPUTE_PAIRWISE_DISTANCES (self, desc1, desc2)
            
            % We are expecting descriptors to be N1xD and N2xD...
            expected_size = self.get_descriptor_size();
            assert(size(desc1, 2) == expected_size, 'Invalid desc1 dimension!');
            assert(size(desc2, 2) == expected_size, 'Invalid desc2 dimension!');
            
            if self.non_binarized_descriptor
                % Apply distance weights to descriptors - alternatively, we
                % could compute separate distances between alpha and gamma
                % parts, and perform weighted sums. Also, the weights could
                % be applied when computing descriptors instead of when
                % computing distances, but the latter seems slightly
                % cleaner...
                desc1(:,1:self.num_circles) = self.A * desc1(:,1:self.num_circles);
                desc1(:,self.num_circles+1:end) = self.G * desc1(:,self.num_circles+1:end);
                
                desc2(:,1:self.num_circles) = self.A * desc2(:,1:self.num_circles);
                desc2(:,self.num_circles+1:end) = self.G * desc2(:,self.num_circles+1:end);
                
                % Compute the distances using cv::batchDistance(); in order to
                % get an N2xN1 matrix, we switch desc1 and desc2
                distances = cv.batchDistance(desc2, desc1, 'K', 0, 'NormType', 'L1');
            else
                % Binarized version
                if self.use_bitstrings
                    distances = alpha_gamma_distances_fast(desc1', desc2', self.num_circles, self.num_rays, self.A, self.G);
                else
                    distances = alpha_gamma_distances(desc1', desc2', self.num_circles, self.num_rays, self.A, self.G);
                end
            end
        end

        function descriptor_size = get_descriptor_size (self)
            if self.non_binarized_descriptor
                % Real-valued version
                descriptor_size = self.num_circles + self.num_circles*self.num_rays;
            else
                % Binary version
                descriptor_size = self.num_circles + self.num_circles*self.num_rays;

                if self.use_bitstrings
                    descriptor_size = ceil( descriptor_size/8 );
                end

                descriptor_size = 2*descriptor_size; % Type 1 and Type 2 effects
            end
        end
    end

    methods (Access = protected)
        function identifier = get_identifier (self)
            identifier = 'AlphaGamma';
        end
    end
    
    % Internal methods
    methods
        function keypoints = filter_keypoints (self, I, keypoints)
            centers = round( vertcat(keypoints.pt) ) + 1;

            outer_sample = self.sample_points{end};
            max_x = max(outer_sample(1,:));
            min_x = min(outer_sample(1,:));
            max_y = max(outer_sample(2,:));
            min_y = min(outer_sample(2,:));

            invalid_idx = centers(:,1) + max_x > size(I,2) | centers(:,1) + min_x < 1 | centers(:,2) + max_y > size(I, 1) | centers(:,2) + min_y < 1;

            % Remove keypoints
            keypoints(invalid_idx) = [];
        end

        function descriptor = extract_descriptor_from_keypoint (self, responses, center, radius_factor, angle)
            % descriptor = EXTRACT_DESCRIPTOR_FROM_KEYPOINT (self, responses, center, radius_factor, angle)
            %
            % Extracts alpha-gamma descriptor from a given keypoint.

            %% Orientation
            if self.orientation_normalized
                % OpenCV keypoints seem to be using opposite angle
                % direction than our code...
                angle = -angle;
            else
                angle = 0;
            end
            
            %% Sample points into the field
            field = nan(self.num_rays, self.num_circles);
            for j = 1:self.num_circles
                for i = 1:self.num_rays
                    point_angle = (i-1) * 2*pi/self.num_rays + deg2rad(angle);
                    x = radius_factor*self.radii(j)*cos(point_angle) + center(1);
                    y = -radius_factor*self.radii(j)*sin(point_angle) + center(2);
                    
                    % Clamp inside valid region
                    x = max(min(x, size(responses, 2)), 1);
                    y = max(min(y, size(responses, 1)), 1);
                    
                    if self.bilinear_sampling
                        % Bilinear interpolation
                        x0 = floor(x);
                        y0 = floor(y);
                        x1 = x0 + 1;
                        y1 = y0 + 1;
                        
                        a0 = x - x0;
                        b0 = y - y0;
                        a1 = 1 - a0;
                        b1 = 1 - b0;
    
                        val = a1*b1*responses(y0,x0,j);
    
                        if a0
                            val = val + a0*b1*responses(y0,x1,j);
                        end
                        if b0
                             val = val + a1*b0*responses(y1,x0,j);
                        end
                        if a0 && b0
                            val = val + a0*b0*responses(y1,x1,j);
                        end
                        
                        field(i, j) = val;
                    else
                        x = round(x);
                        y = round(y);
                        field(i, j) = responses(y, x, j);
                    end
                end
            end
            
            %% Compute descriptor
            gamma = nan(self.num_rays, self.num_circles);
            field_avg = mean(field(:)); % Average value in the field
            
            % Compute alpha effects
            a = mean(field, 1) - field_avg;
            
            % Compute beta effects
            b = mean(field, 2) - field_avg;
            
            % Compute gamma effects
            for j = 1:self.num_circles
                gamma(:,j) = b;
            end
            for j = 1:self.num_rays
                gamma(j,:) = gamma(j,:) + a;
            end
            gamma = field - gamma - field_avg;
            
            % Non-binarized descriptor?
            if self.non_binarized_descriptor
                sa = sqrt( sum(a.*a) / (self.num_circles-1) );
                aa = a / (sa+eps);
                
                sg = sqrt( sum(gamma.*gamma) / (self.num_rays-1) )+eps;
                gg = bsxfun(@rdivide, gamma, sg);
                
                descriptor = [ aa(:); gg(:) ];
                return;
            end
            
            % "Type 1" part of descriptor
            if true
                desc_alpha = reshape(a > 0, [], 1);
                desc_gamma = reshape(gamma > 0, [], 1);
            end
            
            % "Type 2" part of descriptor
            if true
                % Alpha part
                sa = sqrt( sum(a.*a) / (self.num_circles-1) );
                aa = abs(a) > sa*self.threshold_alpha;
                desc_alpha_ext = aa - (1 - aa);
                desc_alpha_ext = reshape(desc_alpha_ext, [], 1);
            
                % Gamma part
                sg = sqrt( sum(gamma.*gamma) / (self.num_rays-1) );
                gg = bsxfun(@gt, abs(gamma), sg*self.threshold_gamma);
                desc_gamma_ext = gg - (1 - gg);
                desc_gamma_ext = reshape(desc_gamma_ext, [], 1);
            end

            %% Write descriptor
            if self.use_bitstrings
                % Bitstring version
                descriptor = [ ...
                    convert_bytestring_to_bitstring( uint8([ desc_alpha; desc_gamma ]) ); ...
                    convert_bytestring_to_bitstring( uint8([ desc_alpha_ext; desc_gamma_ext ]) ) ...
                ];
            else
                % Original byte-string version
                descriptor = [ desc_alpha; desc_gamma; desc_alpha_ext; desc_gamma_ext ];
            end
        end
    end
end

function filt = create_gaussian_filter (sigma)
    % filt = CREATE_GAUSSIAN_FILTER (sigma)
    %
    % Creates a Gaussian filter with specified sigma.

    sz = round(3*sigma);
    [ x, y ] = meshgrid(-sz:sz);

    % DoG
    filt = exp(-(x.^2/sigma^2 + y.^2/sigma^2)/2);
    filt = filt / sum(filt(:));
end
