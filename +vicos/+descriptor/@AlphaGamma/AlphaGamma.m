classdef AlphaGamma < vicos.descriptor.Descriptor
    % ALPHAGAMMA - AlphaGamma descriptor (Matlab version)
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        patch_size = 95
        num_circles = 11
        num_rays = 55
        
        sampling
                
        extended
        extended_threshold
        
        use_scale
        
        base_sigma
        
        % Pre-computed stuff
        filters
        sample_points
        
        % Orientation estimation
        orientation
        orient_cos
        orient_sin
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
            %     - mixed: image pyramid is built using a mixture of
            %       Gaussian and uniform filters, corresponding to the
            %       second revision of the descriptor formulation
            %  - extended: whether to compute extended descriptor (false)
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
            % Output:
            %  - self: @AlphaGamma instance
            
            % Input parameters
            parser = inputParser();
            parser.addParameter('patch_size', 95, @isscalar);
            parser.addParameter('num_circles', 11, @isscalar);
            parser.addParameter('num_rays', 55, @isscalar);
            parser.addParameter('orientation', false, @islogical);
            parser.addParameter('extended', true, @islogical);
            parser.addParameter('sampling', 'gaussian', @ischar);
            parser.addParameter('base_sigma', sqrt(1.7), @isnumeric);
            parser.addParameter('use_scale', false, @islogical);
            parser.addParameter('extended_threshold', 0.674, @isnumeric);
            
            parser.parse(varargin{:});
            
            self.patch_size = parser.Results.patch_size;
            self.num_circles = parser.Results.num_circles;
            self.num_rays = parser.Results.num_rays;
            self.orientation = parser.Results.orientation;
            self.extended = parser.Results.extended;
            self.sampling = parser.Results.sampling;
            self.base_sigma = parser.Results.base_sigma;
            self.use_scale = parser.Results.use_scale;
            self.extended_threshold = parser.Results.extended_threshold;
            
            assert(ismember(self.sampling, { 'simple', 'gaussian', 'mixed' }), 'Invalid sampling type!');
            
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
                    step = sqrt(2);
                    for i = 1:self.num_circles,
                        if i == 1,
                            sigmas(i) = 0.3;
                            radii(i) = 0.71;
                        else
                            sigmas(i) = sigmas(i-1)*step;
                            radii(i) = radii(i-1) + step*sigmas(i);
                        end

                        % Apply filter only if sigma is greater than 0.7
                        if sigmas(i) > 0.7,
                            self.filters{i} = self.create_dog_filter(sigmas(i));
                        else
                            self.filters{i} = [];
                        end
                    end
                case 'mixed',
                    % Mixed filters that was originally used for the extended
                    % descriptor
                    assert(self.num_circles == 11, 'Mixed filters support only 11 circles!');
                
                    step = sqrt(2);
                    for i = 1:self.num_circles,
                        if i == 1,
                            sigmas(i) = 0.3;
                            radii(i) = 0.71;
                        else
                            sigmas(i) = sigmas(i-1)*step;
                            radii(i) = radii(i-1) + step*sigmas(i);
                        end
                    end

                    filter_sizes = [ 1, 1, 1, 1, 3, 3, 5, 5, 7, 9, 11 ];
                    for i = 1:4,
                        self.filters{i} = []; % No filter
                    end
                    for i = 5:7,
                        self.filters{i} = self.create_unif_filter(filter_sizes(i)); % No filter
                    end
                    for i = 8:11,
                        self.filters{i} = self.create_dog_filter(sigmas(i));
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
            % Convert to grayscale
            if size(I, 3) == 3,
                I = rgb2gray(I);
            end

            num_points = numel(keypoints);            
            
            if self.use_scale,
                % Use scale; crop each patch and rescale it to the
                % reference size, then build a pyramid on top of that
                desc = repmat(struct('alpha', [], 'gamma', []), num_points, 1);
                
                for p = num_points:-1:1,
                    w = floor(keypoints(p).size * 3/2);
                    h = floor(keypoints(p).size * 3/2);
                    x = keypoints(p).pt(1);
                    y = keypoints(p).pt(2);
                    
                    xmin = round(x - w);
                    xmax = round(x + w);
                    ymin = round(y - h);
                    ymax = round(y + h);
                    
                    % Crop the patch
                    if ymin < 1 || xmin < 1 || ymax > size(I, 1) || xmax > size(I, 2),
                        test = 1;
                    end
                    
                    patch = self.cut_patch_from_image(I, xmin, xmax, ymin, ymax);
                    patch = imresize(patch, [ self.patch_size, self.patch_size ]);
                    
                    % Compute image pyramid on top of the patch
                    pyramid = zeros(size(patch, 1), size(patch, 2), self.num_circles);
                    base_image = filter2(self.create_dog_filter(self.base_sigma), patch);
                    
                    for i = 1:self.num_circles,
                        if isempty(self.filters{i}),
                            pyramid(:,:,i) = base_image;
                        else
                            pyramid(:,:,i) = filter2(self.filters{i}, base_image);
                        end
                    end
                    
                    % Extract
                    new_center = (size(patch) - 1)/2 + 1;
                    if self.extended,
                        [ desc(p).alpha, desc(p).gamma, desc(p).alpha_ext, desc(p).gamma_ext ] = extract_descriptor_from_keypoint(self, pyramid, new_center);
                    else
                        [ desc(p).alpha, desc(p).gamma ] = extract_descriptor_from_keypoint(self, pyramid, new_center);
                    end
                end
            else
                % Use fixed-size windows; build a single image pyramid for
                % the whole image
                pyramid = zeros(size(I, 1), size(I, 2), self.num_circles);
                base_image = filter2(self.create_dog_filter(self.base_sigma), I);
            
                for i = 1:self.num_circles,
                    if isempty(self.filters{i}),
                        pyramid(:,:,i) = base_image;
                    else
                        pyramid(:,:,i) = filter2(self.filters{i}, base_image);
                    end
                end
           
                % Now extract for each point
                desc = repmat(struct('alpha', [], 'gamma', []), num_points, 1);
                for p = num_points:-1:1,
                    if self.extended,
                        [ desc(p).alpha, desc(p).gamma, desc(p).alpha_ext, desc(p).gamma_ext ] = extract_descriptor_from_keypoint(self, pyramid, keypoints(p).pt);
                    else
                        [ desc(p).alpha, desc(p).gamma ] = extract_descriptor_from_keypoint(self, pyramid, keypoints(p).pt);
                    end
                end
            end
        end
        
        function distances = compute_pairwise_distances (self, desc1, desc2)
            %distances = compute_pairwise_distances_slow(self, desc1, desc2);
            
            if self.extended,
                alphagamma1 = vertcat( uint8([ desc1.alpha ] >= 0), uint8([ desc1.gamma ] >= 0), uint8([ desc1.alpha_ext ] >= 0), uint8([ desc1.gamma_ext ] >= 0) );
                alphagamma2 = vertcat( uint8([ desc2.alpha ] >= 0), uint8([ desc2.gamma ] >= 0), uint8([ desc2.alpha_ext ] >= 0), uint8([ desc2.gamma_ext ] >= 0) );
            else
                alphagamma1 = vertcat( uint8([ desc1.alpha ] >= 0), uint8([ desc1.gamma ] >= 0) );
                alphagamma2 = vertcat( uint8([ desc2.alpha ] >= 0), uint8([ desc2.gamma ] >= 0) );
            end
            
            %distances = alpha_gamma_distances(alphagamma1, alphagamma2, self.num_circles, self.num_rays, self.extended)
            distances = [];
        end
    end
    
    % Internal methods
    methods 
        function [ alpha, gamma, alpha_ext, gamma_ext ] = extract_descriptor_from_keypoint (self, pyramid, center)
            % [ alpha, gamma, alpha_ext, gamma_ext ] = EXTRACT_DESCRIPTOR_FROM_KEYPOINT (self, pyramid, center)
            %
            % Extracts alpha and gamma descriptor from a given keypoint.
            
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
            a = mean(field, 1) - field_avg; % Alpha effects
            b = mean(field, 2) - field_avg; % Beta effects
            
            if self.extended,
                sa = sqrt((sum(a.*a) - sum(a)^2/self.num_circles) / self.num_circles);
                aa = abs(a) > sa*self.extended_threshold;
                alpha_ext = aa - (1 - aa);
                alpha_ext = reshape(alpha_ext, [], 1);
            end
            
            % Gamma effects
            for j = 1:self.num_circles,
                gamma(:,j) = b;
            end
            for j = 1:self.num_rays,
                gamma(j,:) = gamma(j,:) + a;
            end
            gamma = field - gamma - field_avg;
            
            if self.extended,
                sg = sqrt((sum(sum(gamma.*gamma)) - sum(sum(gamma))^2/numel(gamma)) / numel(gamma));
                gg = abs(gamma) > sg*self.extended_threshold;
                gamma_ext = gg - (1 - gg);
                gamma_ext = reshape(gamma_ext, [], 1);
            end
            
            gamma = reshape(sign(gamma), [], 1);
            alpha = reshape(sign(a), [], 1);
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
        
        function distances = compute_pairwise_distances_slow (self, desc1, desc2, varargin)
            parser = inputParser();
            parser.addParameter('A', 5.0, @isnumeric);
            parser.addParameter('B', 0.5, @isnumeric);
            parser.addParameter('G', 1.0, @isnumeric);
            parser.parse(varargin{:});
            
            A = parser.Results.A;
            B = parser.Results.B;
            G = parser.Results.G;

            extended_descriptor = isfield(desc1, 'alpha_ext'); % Do we have an extended descriptor?

            % Merge values (faster access in Matlab)
            alpha1 = [ desc1.alpha ] >= 0;
            alpha2 = [ desc2.alpha ] >= 0;
            gamma1 = [ desc1.gamma ] >= 0;
            gamma2 = [ desc2.gamma ] >= 0;
                        
            if extended_descriptor,
                alpha_ext1 = [ desc1.alpha_ext ] >= 0;
                alpha_ext2 = [ desc2.alpha_ext ] >= 0;
                gamma_ext1 = [ desc1.gamma_ext ] >= 0;
                gamma_ext2 = [ desc2.gamma_ext ] >= 0;
            end
            
            % Compute dimensions of the descriptors
            assert(self.num_circles == size(alpha1, 1), 'Descriptor size mismatch!');
            assert(self.num_rays == size(gamma1, 1) / self.num_circles, 'Descriptor size mismatch!');
            
            num_points1 = numel(desc1);
            num_points2 = numel(desc2);
                        
            % Distance matrix
            distances = nan(num_points2, num_points1);
            
            for i = 1:num_points1,
                for j = 1:num_points2,
                    score_a = sum( abs( alpha1(:,i) - alpha2(:,j) ) );
                    score_b = sum( abs( gamma1(1:self.num_rays,i) - gamma2(1:self.num_rays,j) ) );
                    score_g = sum( abs( gamma1(self.num_rays+1:end,i) - gamma2(self.num_rays+1:end,j) ) );
                        
                    if extended_descriptor,
                        score_a_ext = sum( abs( alpha_ext1(:,i) - alpha_ext2(:,j) ) );
                        score_b_ext = sum( abs( gamma_ext1(1:self.num_rays,i) - gamma_ext2(1:self.num_rays, j) ) );
                        score_g_ext = sum( abs( gamma_ext1(self.num_rays+1:end,i) - gamma_ext2(self.num_rays+1:end, j) ) );
                    else
                        score_a_ext = 0;
                        score_b_ext = 0;
                        score_g_ext = 0;
                    end
                    
                    distances(j,i) = A*score_a + A*score_a_ext + ...
                                     B*score_b + B*score_b_ext + ...
                                     G*score_g + G*score_g_ext;
                end
            end
        end
    end
    
    methods (Static)
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

        function patch = cut_patch_from_image (I, x1, x2, y1, y2)
            % patch = CUT_PATCH_FROM_IMAGE (I, x1, x2, y1, y2)
            %
            % Cuts patch from image with border replication, if necessary.

            % Border replication
            xidx = x1:x2;
            xidx = min(max(xidx, 1), size(I, 2));

            yidx = y1:y2;
            yidx = min(max(yidx, 1), size(I, 1));

            patch = I(yidx, xidx, :);
        end
    end
end