classdef AlphaGamma < vicos.descriptor.Descriptor
    % ALPHAGAMMA - AlphaGamma descriptor (Matlab version)
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>

    properties
        num_circles
        num_rays
        
        base_sigma
        circle_step

        compute_type1
        compute_type2
        
        threshold_alpha
        threshold_gamma

        % Non-binarized
        non_binarized_descriptor
        
        % Scale normalization
        scale_normalized
        base_keypoint_size % Base keypoint size normalization factor
        
        % Orientation normalization
        orientation_normalized
        compute_orientation
        
        % Pre-computed stuff
        radii
        sigmas
        filters

        bilinear_sampling
        
        initial_filter
        
        % Orientation estimation
        orientation_num_rays
        orientation_sample_points
        orientation_cos
        orientation_sin

        % Distance function weights
        A
        G
        
        %
        use_bitstrings
    end

    % vicos.descriptor.Descriptor implementation
    methods
        function self = AlphaGamma (varargin)
            % self = ALPHAGAMMA (varargin)
            %
            % Construct AlphaGamma descriptor extractor.
            %
            % Input: key/value pairs:
            %  - num_circles: number of circles; default: 10
            %  - num_rays: number of rays; default: 23
            %  - circle_step: spacing between two circles; default: sqrt(2)
            %  - base_sigma: sigma for DoG filter of the base image;
            %    default: sqrt(1.7)
            %  - orientation_normalized: normalize w.r.t. keypoint
            %    orientation (default: false). If compute_orientation is
            %    specified, the orientation is estimated by descriptor
            %    extractor; otherwise, the keypoint's orientation is used.
            %  - compute_orientation: whether to estimate orientation or
            %    use the keypoint's angle value; default: true
            %  - orientation_num_rays: number of rays used to estimate the
            %    orientation; default: [] (use num_rays value)
            %  - scale_normalized: whether to use keypoint's size parameter
            %    to extract descriptor from size-normalized patch;
            %    otherwise, descriptor is extracted from fixed-size region.
            %    Default: false
            %  - base_keypoint_size: base factor when converting keypoint
            %    size to patch size; default: 18.5
            %  - bilinear sampling: bilinear sampling of points. Default:
            %    false
            %  - non_binarized_descriptor: whether to compute binarized
            %    descriptor or floating-point descriptor. Default: true
            %    (compute binarized)
            % - compute_type1: compute type 1 part of binarized descriptor.
            %   Default: true
            % - compute_type2: compute type 2 part of binarized descriptor.
            %   Default: true
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
            %   (instead of byte). Default: false
            %
            % Output:
            %  - self: @AlphaGamma instance

            % Input parameters
            parser = inputParser();
            parser.KeepUnmatched = true;            

            parser.addParameter('num_circles', 10, @isscalar);
            parser.addParameter('num_rays', 23, @isscalar);
            parser.addParameter('circle_step', sqrt(2), @isscalar);
            parser.addParameter('base_sigma', sqrt(1.7), @isnumeric);

            parser.addParameter('orientation_normalized', false, @islogical);
            parser.addParameter('compute_orientation', true, @islogical);
            parser.addParameter('orientation_num_rays', [], @isnumeric);
            
            parser.addParameter('scale_normalized', false, @islogical);
            parser.addParameter('base_keypoint_size', 18.5, @isnumeric);

            parser.addParameter('bilinear_sampling', false, @islogical);
            parser.addParameter('non_binarized_descriptor', false, @islogical);
            
            parser.addParameter('compute_type1', true, @islogical);
            parser.addParameter('compute_type2', true, @islogical);
            parser.addParameter('threshold_alpha', [], @isnumeric); % compute from LUT for num_circles-1!
            parser.addParameter('threshold_gamma', [], @isnumeric);
            parser.addParameter('A', 5.0, @isnumeric);
            parser.addParameter('G', 1.0, @isnumeric);
            parser.addParameter('use_bitstrings', false, @islogical);

            parser.parse(varargin{:});
            
            self = self@vicos.descriptor.Descriptor(parser.Unmatched);

            self.num_circles = parser.Results.num_circles;
            self.num_rays = parser.Results.num_rays;
            self.circle_step = parser.Results.circle_step;
            self.base_sigma = parser.Results.base_sigma;
            
            self.orientation_normalized = parser.Results.orientation_normalized;
            self.compute_orientation = parser.Results.compute_orientation;
            self.orientation_num_rays = parser.Results.orientation_num_rays;
                        
            self.scale_normalized = parser.Results.scale_normalized;
            self.base_keypoint_size = parser.Results.base_keypoint_size;
            
            self.bilinear_sampling = parser.Results.bilinear_sampling;
            self.non_binarized_descriptor = parser.Results.non_binarized_descriptor;
            
            self.compute_type1 = parser.Results.compute_type1;
            self.compute_type2 = parser.Results.compute_type2;
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
            
            if isempty(self.orientation_num_rays)
                self.orientation_num_rays = self.num_rays;
            end
            
            %% Pre-compute filters
            sigmas = zeros(self.num_circles, 1);
            radii = zeros(self.num_circles, 1);
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
    
            self.radii = radii;
            self.sigmas = sigmas;
                        
            % Compute filters
            for i = 1:self.num_circles
                if self.sigmas(i) <= 0.7
                    continue;
                end
                
                self.filters{i} = create_dog_filter(sigmas(i));
            end
                        
            %% Orientation estimation parameters
            self.orientation_sample_points = cell(self.num_circles, 1);

            self.orientation_sample_points{1} = zeros(2, self.orientation_num_rays);
            for j = 2:self.num_circles
                points = zeros(2, self.orientation_num_rays);

                for i = 1:self.orientation_num_rays
                    angle = (i-1) * 2*pi/self.orientation_num_rays;
                    x =  radii(j) * cos(angle);
                    y = -radii(j) * sin(angle);

                    points(:, i) = [ x; y ];
                end

                self.orientation_sample_points{j} = points;
            end
            
            %% Orientation correction
            i = 0:self.orientation_num_rays-1;
            self.orientation_cos = cos(2*pi/self.orientation_num_rays*i);
            self.orientation_sin = sin(2*pi/self.orientation_num_rays*i);
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
                pyramid = self.create_image_pyramid(I);
            
                for p = 1:num_points
                    % Extract each point from the first-level pyramid
                    % (which is also the only one we have). Note the 
                    % 0-based to 1-based coordinate system conversion
                    desc(:,p) = extract_descriptor_from_keypoint(self, pyramid, keypoints(p).pt + 1, 1.0, keypoints(p).angle); 
                end
            else
                %% Multi-scale version
                num_octaves = 6;
                
                % Construct pyramids
                pyramids = cell(1, num_octaves);
                
                % Option 1: Resizing of filtered images
                pyramids{1} = self.create_image_pyramid(imresize(I,2));
                for i = 2:num_octaves
                    factor = 0.5^(i-1);
                    pyramids{i} = imresize(pyramids{1}, factor);
                end
                
                % Process all keypoints
                for p = 1:num_points
                    keypoint = keypoints(p);
                    
                    % Determine octave and scale factors
                    if keypoint.size <= 14
                       octave = 1; 
                    elseif keypoint.size <= 28
                  %  if keypoint.size <= 28,
                        octave = 2; % No downsampling
                    elseif keypoint.size <= 56
                        octave = 3; % 1x downsampled
                    elseif keypoint.size <= 112
                        octave = 4; % 2x downsampled
                    elseif keypoint.size <= 224
                        octave = 5; % 3x downsampled
                    elseif keypoint.size <= 448
                        octave = 6; % 4x downsampled
                    else
                        error('Keypoint too large: %f!', keypoint.size);
                    end
                    
                    % Scale the keypoint's center
                    new_center = keypoint.pt - 0.5*(1-2^(octave-2)) + 1;
                    new_center = new_center * 0.5^(octave - 2);
                    
                    % Scale factor for the radii
                    scale_factor = keypoint.size*2/(self.base_keypoint_size * 2^(octave-1));
                    
                    % Extract
                    desc(:,p) = extract_descriptor_from_keypoint(self, pyramids{octave}, new_center, scale_factor, keypoint.angle);
                end
            end
        end
        
        function pyramid = create_image_pyramid (self, I)
            % pyramid = CREATE_IMAGE_PYRAMID (self, I)
            %
            % Creates and image pyramid from the given input image.
            
            pyramid = zeros(size(I, 1), size(I, 2), self.num_circles);
            
            if self.base_sigma ~= 0
                pyramid(:,:,1) = filter2(create_dog_filter(self.base_sigma), I);
            else
                pyramid(:,:,1) = I;
            end
            
            for i = 2:self.num_circles
                if isempty(self.filters{i})
                    pyramid(:,:,i) = pyramid(:,:,i-1);
                else
                    pyramid(:,:,i) = filter2(self.filters{i}, pyramid(:,:,i-1));
                end
            end
        end

        function distances = compute_pairwise_distances (self, desc1, desc2)
            % distances = COMPUTE_PAIRWISE_DISTANCES (self, desc1, desc2)

            % Compatibility layer; if descriptors are given in N1xD and
            % N2xD, transpose them
            desc_size = get_descriptor_size(self);
            if (size(desc1, 1) ~= desc_size && size(desc1, 2) == desc_size)
                desc1 = desc1';
            end
            if (size(desc2, 1) ~= desc_size && size(desc2, 2) == desc_size)
                desc2 = desc2';
            end
            
            if self.non_binarized_descriptor  
                % Compute the distances using cv::batchDistance(); in order to
                % get an N2xN1 matrix, we switch desc1 and desc2
                distances = cv.batchDistance(desc2', desc1', 'K', 0, 'NormType', 'L1');
            else
                % Binarized version
                if self.use_bitstrings
                    distances = alpha_gamma_distances_fast(desc1, desc2, self.num_circles, self.num_rays, self.A, self.G);
                else
                    distances = alpha_gamma_distances(desc1, desc2, self.num_circles, self.num_rays, self.A, self.G);
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

                descriptor_size = self.compute_type1*descriptor_size + self.compute_type2*descriptor_size;
            end
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

        function descriptor = extract_descriptor_from_keypoint (self, pyramid, center, radius_factor, angle)
            % descriptor = EXTRACT_DESCRIPTOR_FROM_KEYPOINT (self, pyramid, center, radius_factor, angle)
            %
            % Extracts alpha-gamma descriptor from a given keypoint.

            %% Orientation
            %% Handle orientation
            if self.orientation_normalized
                % Override angle using built-in angle estimation
                if self.compute_orientation
                    % Sample points into the field
                    field = nan(self.orientation_num_rays, self.num_circles);
                    
                    for j = 1:self.num_circles
                        for i = 1:self.orientation_num_rays
                            x = radius_factor*self.orientation_sample_points{j}(1, i) + center(1);
                            y = radius_factor*self.orientation_sample_points{j}(2, i) + center(2);

                            % Clamp inside valid region
                            x = max(min(x, size(pyramid, 2)), 1);
                            y = max(min(y, size(pyramid, 1)), 1);

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

                                val = a1*b1*pyramid(y0,x0,j);

                                if a0
                                    val = val + a0*b1*pyramid(y0,x1,j);
                                end
                                if b0
                                     val = val + a1*b0*pyramid(y1,x0,j);
                                end
                                if a0 && b0
                                    val = val + a0*b0*pyramid(y1,x1,j);
                                end

                                field(i, j) = val;
                            else
                                x = round(x);
                                y = round(y);
                                field(i, j) = pyramid(y, x, j);
                            end
                        end
                    end
                    
                    % Compute
                    moment_beta = sum(field, 2);
                    angle = atan2d(self.orientation_sin * moment_beta, self.orientation_cos * moment_beta);
                else
                    angle = -angle;
                end
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
                    x = max(min(x, size(pyramid, 2)), 1);
                    y = max(min(y, size(pyramid, 1)), 1);
                    
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
    
                        val = a1*b1*pyramid(y0,x0,j);
    
                        if a0
                            val = val + a0*b1*pyramid(y0,x1,j);
                        end
                        if b0
                             val = val + a1*b0*pyramid(y1,x0,j);
                        end
                        if a0 && b0
                            val = val + a0*b0*pyramid(y1,x1,j);
                        end
                        
                        field(i, j) = val;
                    else
                        x = round(x);
                        y = round(y);
                        field(i, j) = pyramid(y, x, j);
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
            if self.compute_type1
                desc_alpha = reshape(a > 0, [], 1);
                desc_gamma = reshape(gamma > 0, [], 1);
            end
            
            % "Type 2" part of descriptor
            if self.compute_type2
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
                if self.compute_type1 && self.compute_type2
                    % Both types
                    descriptor = [ ...
                        convert_bytestring_to_bitstring( uint8([ desc_alpha; desc_gamma ]) ); ...
                        convert_bytestring_to_bitstring( uint8([ desc_alpha_ext; desc_gamma_ext ]) ) ...
                    ];
                elseif self.compute_type1
                    % Type 1 only
                    descriptor = convert_bytestring_to_bitstring( uint8( [ desc_alpha; desc_gamma ]) );
                elseif self.compute_type2
                    % Type 2 only
                    descriptor = convert_bytestring_to_bitstring( uint8( [ desc_alpha_ext; desc_gamma_ext ]) );
                end
            else
                % Original byte-string version
                if self.compute_type1 && self.compute_type2
                    % Both types
                    descriptor = [ desc_alpha; desc_gamma; desc_alpha_ext; desc_gamma_ext ];
                elseif self.compute_type1
                    % Type 1 only
                    descriptor = [ desc_alpha; desc_gamma ];
                elseif self.compute_type2
                    % Type 2 only
                    descriptor = [ desc_alpha_ext; desc_gamma_ext ];
                end
            end
        end
    end
end

function filt = create_dog_filter (sigma)
    % filt = CREATE_DOG_FILTER (sigma)
    %
    % Creates a DoG filter with specified sigma.

    sz = round(3*sigma);
    [ x, y ] = meshgrid(-sz:sz);

    % DoG
    filt = exp(-(x.^2/sigma^2 + y.^2/sigma^2)/2);
    filt = filt / sum(filt(:));
end