classdef FeatureRadial < vicos.keypoint_detector.KeypointDetector
    % FEATURERADIAL - Radial feature detector
    %
    % RADIAL feature detector from:
    % J. Maver, "Self-similarity and points of interest," IEEE Transactions
    % on Pattern Analysis and Machine Intelligence, vol. 32, no. 7, 
    % pp. 1211-1226, 2010.
    
    properties
        max_features
        
        variance_threshold
        
        num_circles
        min_circle
        
        num_points
        filters
    end
    
    methods
        function self = FeatureRadial (varargin)
            % self = FEATURERADIAL (varagin)
            %
            % Creates Radial feature detector.
            %
            % Input: optional key/value pairs
            %  - VarianceThreshold: value of threshold for variance maps
            %    (default: 0.5)
            %  - NumCircles: number of sampling circles (default: 10)
            %  - MinCircle: minimum keypoint radius (default: 5)
            %  - MaxFeatures: maximum number of returned keypoints
            %    (default: inf).
            %
            % Output:
            %  - self:
            
            % Parse command-line parameters
            parser = inputParser();
            parser.KeepUnmatched = true;
            parser.addParameter('VarianceThreshold', 0.5, @isnumeric);
            parser.addParameter('NumCircles', 10 , @isnumeric);
            parser.addParameter('MinCircle', 5, @isnumeric);
            parser.addParameter('MaxFeatures', inf, @isnumeric);
            parser.parse(varargin{:});
            
            self = self@vicos.keypoint_detector.KeypointDetector(parser.Unmatched);
            
            self.variance_threshold = parser.Results.VarianceThreshold;
            self.num_circles = parser.Results.NumCircles;
            self.min_circle = parser.Results.MinCircle;
            self.max_features = parser.Results.MaxFeatures;
            
            % Pre-compute the sampling filters
            self.num_points = 11*(self.num_circles + 1);
            
            self.filters = cell(self.num_circles, 1);
            
            M = self.num_circles;
            N = self.num_points;
            for i = 1:M
                filter = zeros((i-1)*2 + 1, (i-1)*2 + 1);
                for j = 1:N
                    r = i - 1;
                    x = i + round(r * cos(2*pi/N*(j-1)));
                    y = i + round(r * sin(2*pi/N*(j-1)));
                    
                    filter(y,x) = filter(y,x) + 1;
                end
                
                self.filters{i} = filter;
            end
        end
        
        function keypoints = detect (self, I)    
            % Handle 3-channel images
            if size(I, 3) == 3
                I = rgb2gray(I);
            end
            
            im_orig = double(I);
            im = im_orig;
            max_intensity = max(im(:));
            
            % Compute number of octaves
            M = self.num_circles;
            N = self.num_points;
            
            d = min(size(im, 1), size(im, 2));
            num_octaves = 1;
            
            while (d - 1)/2 > (2*M + 2)
                num_octaves = num_octaves + 1;
                d = d/2;
            end
            num_octaves = min(num_octaves, 3); % 3 octaves at most
            
            % Upscale image for first octave
            im = imresize(im_orig, 2);
            
            % Process all octaves
            features = zeros(5, 0);
            for t = 1:num_octaves
                height = size(im, 1);
                width = size(im, 2);
                
                % Initialize maps (once map for each sampling circle size)
                saliency = zeros(height, width, M); % Saliency maps
                avg = zeros(height, width, M);  % Average of local region weight(1/r) multplied by number of samples
                norm_std = zeros(height, width, M); % Normalized variance, used for thresholding
                
                im2 = im.^2;
                
                % Initialize for center point (first circle)
                C = filter2(self.filters{1}, im, 'same'); % Sample intensities witht the given circle, sum up
                
                avg(:,:,1) = C;
                C2 = C.^2; % Sum of squared C-maps
                
                x2 = filter2(self.filters{1}, im2, 'same'); % Sample squared intensities, sum up
                
                % Compute saliency maps (sampling with all circles)
                for r = 2:M
                    n = r*N; % Number of samples (on all circles so far)
                    
                    C = filter2(self.filters{r}, im, 'same'); % Sample intensities on the r-th circle, sum up
                    
                    avg(:,:,r) = avg(:,:,r-1) + C; % Update average
                    avg2 = avg(:,:,r).^2;
                    
                    C2 = C2 + C.^2; % Update sum of squared C-maps
                    
                    % Update sum of squared intensity values (add sample on
                    % r-th circle)
                    x2 = x2 + filter2(self.filters{r}, im2, 'same');
                    
                    % Saliency map for r-th circle
                    saliency(:,:,r) = (C2 - avg2/r) ./ (N * (x2 - avg2/n + eps));
                    saliency(:,:,r) = averaging_filter(saliency(:,:,r)); % Smooth with averaging filter
                    
                    % Intensity-normalized variance map, used for
                    % thresholding
                    norm_std(:,:,r) = sqrt((C2 - avg2/r) / (n*max_intensity^2));
                end
                
                % Detect features and compute their orientations
                features_t = find_local_scale_space_maxima(self.min_circle, t, saliency, norm_std, avg, self.variance_threshold);
                
                % Append along 2nd dimension!
                features = [ features, features_t' ];  %#ok<AGROW>
                
                % Downsample for next octave
                if t == 1
                    im = im_orig; % Original image (because first octave was upsampled)
                else
                    im = imresize(im, 0.5);
                end
            end
            
            features = features'; % Switch from column-major to row-major order
            
            %% Create output
            % Sort by response values, restrict number of returned
            % keypoints, if necessary
            [ ~ , idx] = sort(features(:,4), 'descend');
            num_keypoints = min(size(features, 1), self.max_features);
            features = features(idx(1:num_keypoints), :);
            
            % Create OpenCV keypoint array
            keypoints = repmat(struct('pt', [ 0, 0 ], 'size', 0, 'angle', 0, 'response', 0, 'octave', int32(0), 'class_id', int32(-1)), 1, num_keypoints);
            for p = 1:num_keypoints
                keypoints(p).pt =( [ features(p, 1), features(p, 2) ]) - 1; % (x,y), 0-based indexing
                keypoints(p).size = 1 / features(p, 3) + 1; % Keypoint size
                keypoints(p).angle = features(p, 5);
                keypoints(p).response = features(p, 4);
                keypoints(p).octave = 0;
                keypoints(p).class_id = -1;
            end
        end
    end
    
    methods (Access = protected)
        function identifier = get_identifier (self)
            identifier = 'Radial';
        end
    end
end


function features = find_local_scale_space_maxima (min_scale, t, saliency, norm_std, avg, variance_threshold)
    % features = FIND_LOCAL_SCALE_SPACE_MAXIMA (min_scale, t, saliency, norm_std, avg, variance_threshold)
    %
    % Searches for local scale-space maxima in saliency maps, verifies
    % them, and computes orientation.
    %
    % Input:
    %  - min_scale: minimum keypoint radius
    %  - t: octave; (t-2) indicates how many times the input image has been
    %    downsampled
    %  - saliency: saliency maps
    %  - norm_std: normalized variance maps
    %  - avg: average maps (for orientation estimation)
    %  - variance_threshold: variance threshold
    %
    % Output:
    %  - features: Nx5 matrix with keypoint entries. Each entry consists of
    %    the following values: [ x, y, size, response, angle ]
    
    features = zeros(0, 5);
    M = size(saliency, 3); % Number of circles 
    
    for s = min_scale:M-1
        tmp = saliency(s+2:end-s-1, s+2:end-s-1, s);
        
        % Maxima across three levels
        ctm = max(norm_std(s+2:end-s-1,s+2:end-s-1,s-1:s+1), [], 3);
        v   = max(saliency(s+1:end-s,s+1:end-s,s-1:s+1), [], 3);
        maxima = tmp >= v(2:end-1,1:end-2) & tmp >= v(2:end-1,3:end) & ...
                 tmp >= v(1:end-2,2:end-1) & tmp >= v(3:end,2:end-1) & ...
                 tmp >= v(1:end-2,1:end-2) & tmp >= v(1:end-2,3:end) & ...
                 tmp >= v(3:end  ,1:end-2) & tmp >= v(3:end,3:end)   & ...
                 tmp == v(2:end-1,2:end-1) & ctm > variance_threshold;
        
        [ y_loc, x_loc ] = find(maxima);
        v = ctm(maxima > 0);
        
        % Verify and prune bad exterma
        if size(x_loc, 1) > 0
            [ x_loc, y_loc, v ] = validate_extrema(x_loc, y_loc, v, saliency(s:end-s+1, s:end-s+1, s), 9.25);
            radius = s*ones(numel(x_loc), 1);
            
            % Coordinates in original saliency maps, saliency(:,:,s)
            xn = x_loc + s + 1;
            yn = y_loc + s + 1;
            
            % Compute orientation
            [ xn, yn, radius, angle, response ] = compute_orientation(avg(:,:,s), xn, yn, radius, v);
            scale = 1 ./ ((radius-1) .* 2^(t-1));
            
            % Keypoints in original images (undo scaling)
            x = xn*2^(t-2) + 0.5*(1-2^(t-2));
            y = yn*2^(t-2) + 0.5*(1-2^(t-2));
            
            features = vertcat(features, [ x, y, scale, response, angle ]); %#ok<AGROW>
        end
    end
end

function Io = averaging_filter (I)
    % Io = AVERAGING_FILTER (I)
    %
    % Filters given input image with 3x3 averaging filter.
    
    % Construct filter
    h = ones(3, 3);
    h = h / sum(h(:));
    
    % Filter; equivalent to cv.blur(I, 'KSize', [ 3, 3 ], 'BorderType', 'Replicate');
    Io = imfilter(I, h, 'replicate');
end

function [ x_loc, y_loc, response ] = validate_extrema (x_loc, y_loc, response, saliency, threshold)
    % [ x, y, v ] = VALIDATE_EXTREMA (x, y, v, saliency, threshold)
    %
    % Validates the given set of local scale-space extema, purging the ones
    % with low contrast (same mechanism as in SIFT).
    %
    % Input:
    %  - x_loc: Nx1 array of x coordinates in the given saliency map
    %  - y_loc: Nx1 array of y coordinates in the given saliency map
    %  - response: Nx1 array of corresponding responses
    %  - saliency: saliency map
    %  - threshold: edge threshold
    %
    % Output: filtered extrema
    %  - x_loc: Mx1 array of x coordinates
    %  - y_loc: Mx1 array of y coordinates
    %  - response: Mx1 array of response values
    
    valid = false(numel(x_loc), 1);
    
    for i = 1:numel(x_loc)
        % Shift due to larger input saliency map
        x = x_loc(i) + 2;
        y = y_loc(i) + 2;
        
        center_value = 2 * saliency(y,x);
        dXX = saliency(y,x-1) + saliency(y,x+1) - center_value;
        dYY = saliency(y+1,x) + saliency(y-1,x) - center_value;
        dXY = 0.25 * (saliency(y+1,x+1) - saliency(y+1,x-1) - saliency(y-1,x+1) + saliency(y-1,x-1));
        
        TrH = dXX + dYY;
        DetH = dXX * dYY - dXY^2;
        if abs(TrH^2/DetH) <  threshold
            valid(i) = true; % Keep
        end
    end
    
    % Purge invalid
    x_loc(~valid) = [];
    y_loc(~valid) = [];
    response(~valid) = [];
end


function [ xo, yo, so, ao, vo ] = compute_orientation (I, xx, yy, ss, vv)
    % [ xo, yo, so, ao, vo ] = COMPUTE_ORIENTATION (I, xx, yy, ss, vv)
    %
    % Computes orientation for given keypoints. If multiple orientations
    % are possible, the keypoints are duplicated.
    %
    % Input:
    %  - I: input image
    %  - xx: Nx1 array of x coordinates in the image
    %  - yy: Nx1 array of y coordinates in the image
    %  - ss: Nx1 array of sampling circle radii
    %  - vv: Nx1 array of corresponding response values
    %
    % Output:
    %  - xo: Mx1 array of x coordinates
    %  - yo: Mx1 array of y coordinates
    %  - so: Mx1 array of radii
    %  - ao: Mx1 array of angles
    %  - vo: Mx1 array of response values
    
    % Compute image gradients
    height = size(I, 1);
    width = size(I, 2);
    
    dX = zeros(height, width);
    dY = zeros(height, width);
    dX(:,2:end-1) = I(:,3:end) - I(:,1:end-2);
    dY(2:end-1,:) = I(1:end-2,:) - I(3:end,:);
    mag = sqrt(dX.^2 + dY.^2);
    phi = atan2(dY, dX);
    
    % Discretize orientation; each bin covers 10 degrees; -pi is 1st bin,
    % pi is 37th bin; at the end, 1st and 37th bin are combined
    N = 36;
    phi = round(phi*18/pi+18) + 1;

    % Process all keypoints
    xo = [];
    yo = [];
    so = [];
    ao = [];
    vo = [];
    
    for n = 1:numel(xx)
        x = round(xx(n));
        y = round(yy(n));
        
        sigma = ss(n)*1.5; % Gaussian weighting for gradient
        s = round(3.5*ss(n)); % Sampling radius
    
        % Sample gradient from patch
        x1 = max(x-s, 1);
        x2 = min(x+s, width);
        y1 = max(y-s, 1);
        y2 = min(y+s, height);
        
        hist = zeros(N+1, 1); % One more bin to handle wrap-around
        for j = y1:y2
            for i = x1:x2
                idx = phi(j,i); % Bin index
                w = exp(-((x-i)^2 + (y-j)^2)/(2*sigma^2)); % Gaussian weight
                hist(idx) = hist(idx) + w*mag(j,i);
            end
        end
        hist(1) = hist(1) + hist(end); % Merge first and last bin
        hist(end) = 0;
        
        % Find all valid orientation. For each valid bin, check if it is a
        % local maximum. If it is, interpolate orientation; otherwise,
        % discard
        valid_idx = find(hist > 0.85*max(hist));
        
        for i = 1:numel(valid_idx)
            idx = valid_idx(i);
            
            % Handle wrap-around by explicitly considering the edge cases
            if idx == 1
                if hist(1) > hist(2) && hist(1) > hist(N)
                    h1 = hist(N);
                    h2 = hist(1);
                    h3 = hist(2);
                else
                    continue;
                end
            elseif idx == N
                if hist(N) > hist(N-1) && hist(N) > hist(1)
                    h1 = hist(N-1);
                    h2 = hist(N);
                    h3 = hist(1);
                else
                    continue;
                end
            else
                if hist(idx) > hist(idx-1) && hist(idx) > hist(idx+1)
                    h1 = hist(idx-1);
                    h2 = hist(idx);
                    h3 = hist(idx+1);
                else
                    continue;
                end
            end
            
            % Interpolate angle
            angle = 10*(idx-1) + 5*(h1 - h3)/(h1 + h3 - 2*h2);
            
            % Append to output
            xo(end+1,1) = xx(n); %#ok<AGROW>
            yo(end+1,1) = yy(n); %#ok<AGROW>
            so(end+1,1) = ss(n); %#ok<AGROW>
            ao(end+1,1) = -angle; %#ok<AGROW>
            vo(end+1,1) = vv(n); %#ok<AGROW>
        end
    end
end
