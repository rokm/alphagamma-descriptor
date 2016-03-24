classdef AlphaGamma < vicos.descriptor.Descriptor
    % ALPHAGAMMA - AlphaGamma descriptor (Matlab version)
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>

    properties
        patch_size = 95
        num_circles = 11
        num_rays = 55
        circle_step = sqrt(2)

        sampling

        compute_base
        compute_extended
        threshold_alpha
        threshold_gamma

        use_scale
        scale_factor = 23 % Default for SIFT keypoints

        base_sigma

        % Pre-computed stuff
        filters
        sample_points

        % Orientation estimation
        orientation
        orient_cos
        orient_sin

        % Distance function weights
        A
        G

        %
        effective_patch_size = 95
        
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
            %  - patch_size: size of a patch (95)
            %  - num_circles: number of circles (11)
            %  - num_rays: number of rays (55)
            %  - orientation: whether to estimate and correct orientation
            %    (false)
            %  - sampling: sampling type:
            %     - simple: only base image is filtered; results in the
            %       simple version of descriptor
            %     - gaussian: image pyramid is built using a bank of
            %       Gaussian filter, corresponding to the original complex
            %       descriptor formulation
            %  - extended_threshold: threshold to use in extended
            %    descriptor (0.674)
            %  - base_sigma: sigma for DoG filter of the base image.
            %    Original formulation used sqrt(2), while the later ones
            %    used sqrt(1.7), which is also the default now
            %  - use_scale: use keypoints' scale information to crop
            %    patches and rescale them to the reference size before
            %    computing the descriptor. Otherwise, fixed reference-sized
            %    windows are extracted around the keypoints' locations.
            %    Default: false.
            %
            % - compute_base: compute base descriptor
            % - compute_extended: compute extended descriptor
            % - threshold_alpha:
            % - threshold_gamma:
            % - A:
            % - G:
            % - use_bitstrings:
            %
            % Output:
            %  - self: @AlphaGamma instance

            % Input parameters
            parser = inputParser();
            parser.addParameter('patch_size', 95, @isscalar);
            parser.addParameter('num_circles', 11, @isscalar);
            parser.addParameter('num_rays', 55, @isscalar);
            parser.addParameter('circle_step', sqrt(2), @isscalar);
            parser.addParameter('orientation', false, @islogical);
            parser.addParameter('sampling', 'gaussian', @ischar);
            parser.addParameter('base_sigma', sqrt(1.7), @isnumeric);
            parser.addParameter('use_scale', false, @islogical);

            parser.addParameter('compute_base', true, @islogical);
            parser.addParameter('compute_extended', true, @islogical);
            parser.addParameter('threshold_alpha', [], @isnumeric); % compute from LUT for num_circles-1!
            parser.addParameter('threshold_gamma', [], @isnumeric);
            parser.addParameter('A', 5.0, @isnumeric);
            parser.addParameter('G', 1.0, @isnumeric);
            parser.addParameter('use_bitstrings', false, @islogical);

            parser.parse(varargin{:});

            self.patch_size = parser.Results.patch_size;
            self.num_circles = parser.Results.num_circles;
            self.num_rays = parser.Results.num_rays;
            self.circle_step = parser.Results.circle_step;
            self.orientation = parser.Results.orientation;
            self.sampling = parser.Results.sampling;
            self.base_sigma = parser.Results.base_sigma;
            self.use_scale = parser.Results.use_scale;
            
            self.compute_base = parser.Results.compute_base;
            self.compute_extended = parser.Results.compute_extended;
            self.threshold_alpha = parser.Results.threshold_alpha;
            self.threshold_gamma = parser.Results.threshold_gamma;
            self.A = parser.Results.A;
            self.G = parser.Results.G;
            self.use_bitstrings = parser.Results.use_bitstrings;

            assert(ismember(self.sampling, { 'simple', 'gaussian' }), 'Invalid sampling type!');

            % Determine thresholds as the inverse of Student's T CDF with
            % number of elements in alpha or gamma (minus 1) as degrees of
            % freedom, and 50% confidence interval
            if isempty(self.threshold_alpha),
                dof = self.num_circles - 1;
                self.threshold_alpha = tinv(1 - 0.5/2, dof);
            end
            if isempty(self.threshold_gamma),
                dof = self.num_rays - 1;
                self.threshold_gamma = tinv(1 - 0.5/2, dof);
            end
            
            %% Pre-compute filters
            sigmas = zeros(self.num_circles, 1);
            radii = zeros(self.num_circles, 1);
            self.filters = cell(self.num_circles, 1);

            switch self.sampling,
                case 'simple',
                    scale_factor = (self.patch_size-1) / (2*self.num_circles);

                    % Filters are intentionally left empty

                    % Compute radii
                    for i = 2:self.num_circles+1,
                        radii(i) = scale_factor*(i-1);
                    end
                case 'gaussian',
                    % Pure bank of Gaussian filters that was used with original
                    % version of complex descriptor
                    %step = sqrt(2);
                    step = self.circle_step;
                    for i = 1:self.num_circles,
                        if i == 1,
                            %sigmas(i) = 0.3;
                            %radii(i) = 0.71;
                            sigmas(i) = 0.3; % Variable
                            radii(i) = 0.71/0.3 * sigmas(i);
                            continue; % Do not do anything
                        else
                            sigmas(i) = sigmas(i-1)*step;
                            radii(i) = radii(i-1) + step*sigmas(i);
                        end

                        % Apply filter only if sigma is greater than 0.7
                        if sigmas(i) <= 0.7,
                            continue;
                        end
                        
                        if isempty(self.filters{i-1}),
                            % We do not have previous filter; create a 
                            % full filter
                            self.filters{i} = create_dog_filter(sigmas(i));
                        else
                            % We have previous filter; compute incremental
                            % filter
                            tmp_sigma = sqrt( sigmas(i)^2 - sigmas(i-1)^2 );
                            self.filters{i} = create_dog_filter(tmp_sigma);
                        end
                    end
            end

            %% Compute sampling points
            self.sample_points = cell(self.num_circles, 1);

            self.sample_points{1} = zeros(2, self.num_rays);
            for j = 2:self.num_circles,
                points = zeros(2, self.num_rays);

                for i = 1:self.num_rays,
                    angle = (i-1) * 2*pi/self.num_rays;
                    x =  round(radii(j) * cos(angle));
                    y = -round(radii(j) * sin(angle));

                    points(:, i) = [ x; y ];
                end

                self.sample_points{j} = points;
            end

            %% Orientation correction
            i = 0:self.num_rays-1;
            self.orient_cos = cos(2*pi/self.num_rays*i);
            self.orient_sin = sin(2*pi/self.num_rays*i);
        end

        function [ desc, keypoints ] = compute (self, I, keypoints)

            % NOTE: keypoints' coordinates are zero-based as we use OpenCV
            % convention; therefore, we need to convert them to 1-based
            % indices (and round them) - this is done below, when calling
            % extract_descriptor_from_keypoint()

            % Convert to grayscale
            if size(I, 3) == 3,
                I = rgb2gray(I);
            end

            % Filter out keypoints that are too close to the image border
            keypoints = self.filter_keypoints(I, keypoints);

            num_points = numel(keypoints);

            desc = zeros(get_descriptor_size(self), num_points, 'uint8');

            if self.use_scale,
                % Use scale; crop each patch and rescale it to the
                % reference size, then build a pyramid on top of that
                for p = 1:num_points,
                    % Round the keypoint coordinates to integer; convert
                    % from 0-based to 1-based coordinate system
                    x = round(keypoints(p).pt(1)) + 1;
                    y = round(keypoints(p).pt(2)) + 1;

                    % Apply patch scale conversion
                    w = round(keypoints(p).size * self.scale_factor);
                    h = round(keypoints(p).size * self.scale_factor);
                    
                    % Keep scale odd
                    if ~mod(w, 2),
                        w = w + 1;
                    end
                    if ~mod(h, 2),
                        h = h + 1;
                    end

                    % Crop the patch
                    patch = cut_patch_from_image(I, x, y, w, h);

                    % Resize patch to the reference size (patch size plus
                    % 2 x size of the largest filter)
                    filter_size = (size(self.filters{end},1) - 1) / 2;
                    reference_size = self.patch_size + 2*filter_size;
                    patch = imresize(patch, [ reference_size, reference_size ]);

                    % Compute image pyramid on top of the patch
                    pyramid = zeros(size(patch, 1), size(patch, 2), self.num_circles);
                    base_image = filter2(create_dog_filter(self.base_sigma), patch);

                    for i = 1:self.num_circles,
                        if isempty(self.filters{i}),
                            pyramid(:,:,i) = base_image;
                        else
                            pyramid(:,:,i) = filter2(self.filters{i}, base_image);
                        end
                    end

                    % Extract
                    new_center = (size(patch) - 1)/2;
                    desc(:,p) = extract_descriptor_from_keypoint(self, pyramid, new_center);
                end
            else
                % Use fixed-size windows; build a single image pyramid for
                % the whole image
                pyramid = zeros(size(I, 1), size(I, 2), self.num_circles);
                base_image = filter2(create_dog_filter(self.base_sigma), I);

                pyramid(:,:,1) = base_image;
                for i = 2:self.num_circles,
                    if isempty(self.filters{i}),
                        pyramid(:,:,i) = pyramid(:,:,i-1);
                    else
                        pyramid(:,:,i) = filter2(self.filters{i}, pyramid(:,:,i-1));
                    end
                end

                % Now extract for each point (note the 0-based to 1-based
                % coordinate system conversion)
                for p = 1:num_points,
                    desc(:,p) = extract_descriptor_from_keypoint(self, pyramid, keypoints(p).pt + 1);
                end
            end
        end

        function distances = compute_pairwise_distances (self, desc1, desc2)
            % distances = COMPUTE_PAIRWISE_DISTANCES (self, desc1, desc2)

            % Compatibility layer; if descriptors are given in N1xD and
            % N2xD, transpose them
            desc_size = get_descriptor_size(self);
            if (size(desc1, 1) ~= desc_size && size(desc1, 2) == desc_size),
                desc1 = desc1';
            end
            if (size(desc2, 1) ~= desc_size && size(desc2, 2) == desc_size),
                desc2 = desc2';
            end

            if self.use_bitstrings,
                distances = alpha_gamma_distances_fast(desc1, desc2, self.num_circles, self.num_rays, self.A, self.G);
            else
                distances = alpha_gamma_distances(desc1, desc2, self.num_circles, self.num_rays, self.A, self.G);
            end
        end

        function descriptor_size = get_descriptor_size (self)
            descriptor_size = self.num_circles + self.num_circles*self.num_rays;
            
            if self.use_bitstrings,
                descriptor_size = ceil( descriptor_size/8 );
            end
            
            descriptor_size = self.compute_base*descriptor_size + self.compute_extended*descriptor_size;
        end

        function decriptor = compute_from_patch (self, I)
            % Resize to patch size
            I = imresize(I, [ self.effective_patch_size, self.effective_patch_size ]);

            % Keypoint position: center of the patch
            [ h, w, ~ ] = size(I);
            keypoint.pt = ([ w, h ] - 1) / 2; % NOTE: we use OpenCV convention and 0-based coordinate system here, because compute() method will convert it to 1-based one...

            % We do not need to specify keypoint size here, because we are
            % not using mexopencv...

            % Compute descriptor for the keypoint
            decriptor = self.compute(I, keypoint);
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

        function descriptor = extract_descriptor_from_keypoint (self, pyramid, center)
            % descriptor = EXTRACT_DESCRIPTOR_FROM_KEYPOINT (self, pyramid, center)
            %
            % Extracts alpha-gamma descriptor from a given keypoint.

            center = round(center);

            %% Sample points into the field
            field = nan(self.num_rays, self.num_circles);
            gamma = nan(self.num_rays, self.num_circles);

            for j = 1:self.num_circles,
                for i = 1:self.num_rays,
                    x = self.sample_points{j}(1, i) + center(1);
                    y = self.sample_points{j}(2, i) + center(2);
                    field(i, j) = pyramid(y, x, j);
                end
            end

            %% Handle orientation
            if self.orientation,
                moment_beta = sum(field, 2);

                angle = atan2(self.orient_sin * moment_beta, self.orient_cos * moment_beta) * 180/pi;
                shift = -round(angle * self.num_rays/360);

                %shift = shift + 1; %% NOTE: this hack makes result compliant with original implementation!

                field = circshift(field, shift, 1); % Circularly shift along the first dimension
            end

            %% Compute descriptor
            field_avg = mean(field(:)); % Average value in the field
            
            % Compute alpha effects
            a = mean(field, 1) - field_avg;
            
            % Compute beta effects
            b = mean(field, 2) - field_avg;

            % Compute gamma effects
            for j = 1:self.num_circles,
                gamma(:,j) = b;
            end
            for j = 1:self.num_rays,
                gamma(j,:) = gamma(j,:) + a;
            end
            gamma = field - gamma - field_avg;
            
            % "Basic" part of descriptor
            if self.compute_base,
                desc_alpha = reshape(a > 0, [], 1);
                desc_gamma = reshape(gamma > 0, [], 1);
            end
            
            % "Extended" part of descriptor
            if self.compute_extended,
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
            if self.use_bitstrings,
                % Bitstring version
                if self.compute_base && self.compute_extended,
                    % Combined
                    descriptor = [ ...
                        convert_bytestring_to_bitstring( uint8([ desc_alpha; desc_gamma ]) ); ...
                        convert_bytestring_to_bitstring( uint8([ desc_alpha_ext; desc_gamma_ext ]) ) ...
                    ];
                elseif self.compute_base,
                    % Base-only
                    descriptor = convert_bytestring_to_bitstring( uint8( [ desc_alpha; desc_gamma ]) );
                elseif self.compute_extended,
                    % Extended-only
                    descriptor = convert_bytestring_to_bitstring( uint8( [ desc_alpha_ext; desc_gamma_ext ]) );
                end
            else
                % Original byte-string version
                if self.compute_base && self.compute_extended,
                    % Combined
                    descriptor = [ desc_alpha; desc_gamma; desc_alpha_ext; desc_gamma_ext ];
                elseif self.compute_base,
                    % Base-only
                    descriptor = [ desc_alpha; desc_gamma ];
                elseif self.compute_extended,
                    % Extended-only
                    descriptor = [ desc_alpha_ext; desc_gamma_ext ];
                end
            end
        end

        function fig = visualize_descriptor (self)
            fig = figure('Name', 'Descriptor visualization');

            patch = zeros(self.patch_size, self.patch_size, 1, 'uint8');

            imshow(patch);
            hold on;

            center_x = (self.patch_size - 1)/2 + 1;
            center_y = (self.patch_size - 1)/2 + 1;

            for c = 1:self.num_circles,
                for r =1:self.num_rays,
                    x = center_x + self.sample_points{c}(1,r);
                    y = center_y + self.sample_points{c}(2,r);
                    plot(x, y, 'r+');
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

function filt = create_unif_filter (window)
    % filt = CREATE_UNIF_FILTER (window)
    %
    % Creates a uniform filter with specified window size.

    filt = ones(window, window);
    filt = filt / sum(filt(:));
end

function patch = cut_patch_from_image (I, x, y, w, h)
    % patch = CUT_PATCH_FROM_IMAGE (I, x, y, w, h)
    %
    % Cuts patch from image with border replication, if necessary.
    
    assert(mod(w,2) == 1, 'Patch must be of odd size!');
    assert(mod(h,2) == 1, 'Patch must be of odd size!');

    w2 = (w-1)/2;
    h2 = (h-1)/2;

    % Border replication
    xidx = (x-w2):(x+w2);
    xidx = min(max(xidx, 1), size(I, 2));

    yidx = (y-h2):(y+h2);
    yidx = min(max(yidx, 1), size(I, 1));

    patch = I(yidx, xidx, :);
end