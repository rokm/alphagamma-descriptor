classdef FeatureRadial < vicos.keypoint_detector.KeypointDetector
    % FEATURERADIAL - Radial feature detector
    
    properties
        saliency_threshold
        variance_threshold
        
        num_circles
        
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
            %  - Threshold:
            %  - NumScales:
            
            parser = inputParser();
            parser.KeepUnmatched = true;
            parser.addParameter('SaliencyThreshold', 0.3, @isnumeric);
            parser.addParameter('VarianceThreshold', 3.75, @isnumeric);
            parser.addParameter('NumCircles', 10 , @isnumeric);
            parser.parse(varargin{:});
            
            self = self@vicos.keypoint_detector.KeypointDetector(parser.Unmatched);
            
            self.saliency_threshold = parser.Results.SaliencyThreshold;
            self.variance_threshold = parser.Results.VarianceThreshold;
            self.num_circles = parser.Results.NumCircles;
            
            % Pre-compute the filters
            self.num_points = 11*(self.num_circles + 1);
            
            self.filters = cell(self.num_circles, 1);
            
            M = self.num_circles;
            N = self.num_points;
            for i = 1:M,
                filter = zeros((i-1)*2 + 1, (i-1)*2 + 1);
                for j = 1:N,
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
            if size(I, 3) == 3,
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
            
            while (d - 1)/2 > (2*M + 2),
                num_octaves = num_octaves + 1;
                d = d/2;
            end
            num_octaves = min(num_octaves, 3); % 3 octaves at most
            
            % Upscale image for first octave
            im = imresize(im_orig, 2);
            
            % Process all octaves
            features = [];
            for t = 1:num_octaves,
                height = size(im, 1);
                width = size(im, 2);
                
                saliency = zeros(height, width, M);
                n_average_x = zeros(height, width, M);
                total_ss = zeros(height, width, M);
                
                im2 = im.^2;
                
                % Initialization for anulli
                sum_st  = filter2(self.filters{1}, im,  'same');
                sum_st2 = filter2(self.filters{1}, im2, 'same');
                
                n_average_x(:,:,1) = sum_st;
                n_average_x2 = n_average_x(:,:,1).^2;
                x_2 = sum_st2;
                xyc = n_average_x2;
                
                % Anulli
                for r = 2:M,
                    n = r*N;
                    sum_st  = filter2(self.filters{r}, im,  'same');
                    sum_st2 = filter2(self.filters{r}, im2, 'same');
                    
                    x_2 = x_2 + sum_st2;
                    n_average_x(:,:,r) = n_average_x(:,:,r-1) + sum_st;
                    
                    n_average_x2 = n_average_x(:,:,r).^2;
                    xyc = xyc + sum_st.^2;
                    total_ss(:,:,r) = (x_2-n_average_x2/n) + eps;
                    saliency(:,:,r) = (xyc-n_average_x2/r)./total_ss(:,:,r)/N;
                    
                    total_ss(:,:,r) = sqrt((xyc-n_average_x2/r)/N/r/max_intensity);
                    
                    saliency(:,:,r) = averaging(saliency(:,:,r));
                end
                
                if t == 1,
                    R_min = 5;
                else
                    R_min = floor((M+1)/2);
                end
                
                features = vertcat(features, find_LSSM(R_min, t, saliency, total_ss, self.saliency_threshold, self.variance_threshold, n_average_x));
                
                % Prepare image for next octave
                if t == 1,
                    im = im_orig; % Original image (because first octave was upsampled)
                else
                    im = imresize(im, 0.5); % Downscale
                end
            end
            
            %% Create output
            % Limit the number of keypoints
            num_keypoints = size(features, 1);
            if num_keypoints > 20000,
                [ ~ , idx] = sort(features(:,4), 'descend');
                features = features(idx(1:20000), :);
                num_keypoints = 20000;
            end
            
            % Copy to OpenCV structure
            keypoints = repmat(struct('pt', [ 0, 0 ], 'size', 0, 'angle', 0, 'response', int32(0), 'octave', 0, 'class_id', -1), num_keypoints, 1);
            for p = 1:num_keypoints,
                keypoints(p).pt =( [ features(p, 2), features(p, 1) ]) - 1; %(x,y)
                keypoints(p).size = 1/ features(p, 3) + 1;
                keypoints(p).angle = features(p, 5);
                keypoints(p).response = 0; %features(p, 4);
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

function features = find_LSSM(R_min, t, saliency, variance, saliency_threshold, variance_threshold, average)
    % features = FIND_LSSM (R_min, t, saliency, variance, saliency_threshold, variance_threshold, average)
    %
    % Finds local scale-space maxima.
    %
    % Input:
    %  - R_min: R_min + 1 is the radius of the smallest feature
    %  - t: octave; t - 1 tells us how many times the input image was
    %    downsampled
    %  - saliency: saliency maps
    %  - variance: variance of local region
    %  - saliency_threshold: threshold for saliency
    %  - variance_threshold: threshold for variance
    %  - average: average value of local region
    
    features = [];
    M = size(saliency,3);
    
    D = 5; % Ignore border
    
    for sc = R_min:M-1,
        tmp = saliency(sc+2+D:end-sc-1-D, sc+2+D:end-sc-1-D, sc);
        
        ct = variance(sc+2+D:end-sc-1-D, sc+2+D:end-sc-1-D,sc);
        
        % Maxima of three neighbour scales
        v = max(saliency(sc+1+D:end-sc-D,sc+1+D:end-sc-D,sc-1:sc+1), [], 3); % Maximum across scales
        maxima = tmp >= v(2:end-1,1:end-2) & tmp >= v(2:end-1,3:end) & ...
                 tmp >= v(1:end-2,2:end-1) & tmp >= v(3:end,2:end-1) & ...
                 tmp >= v(1:end-2,1:end-2) & tmp >= v(1:end-2,3:end) & ...
                 tmp >= v(3:end  ,1:end-2) & tmp >= v(3:end,3:end)   & ...
                 tmp == v(2:end-1,2:end-1) & ct > variance_threshold &  tmp >saliency_threshold ;
             
        [ y_loc, x_loc ] = find(maxima);
        v = tmp(maxima > 0);
        
        if size(x_loc,1) > 0,
            [ x_loc, y_loc, v ] = validate_extrema(x_loc, y_loc, v, saliency(sc+D:end-sc+1-D, sc+D:end-sc+1-D, sc), 9.25);
            scale = ones(length(x_loc),1)*sc;
            xn = x_loc + 1 + sc + D;
            yn = y_loc + 1 + sc + D;
            [ xn, yn, scale, angle, v ] = compute_orientation(average(:,:,sc), xn, yn, scale, v);
            rn = ones(size(xn,1),1) ./ ((scale-1).*2^(t-1));
            
            features = [ features; [ yn*2^(t-2)+0.5*(1-2^(t-2)), xn*2^(t-2)+0.5*(1-2^(t-2)), rn, v, angle] ];
        end
    end
end

function If = averaging (I)
    % average of 9 neighboring pixels
    height = size(I, 1);
    width = size(I, 2);
    
    vect = zeros(height+2,width+2);
    vect(2:1+height,2:width+1) = I;
    vect(:,2:end-1) = vect(:,1:end-2) + vect(:,2:end-1) + vect(:,3:end);
    vect(2:end-1,:) = vect(1:end-2,:) + vect(2:end-1,:) + vect(3:end,:);
    
    If = 1/9*vect(2:end-1,2:end-1);
end


function [ xo, yo, vo ] = validate_extrema (xx, yy, vv, s, tr)
    num_points = size(xx, 1);
    
    valid = false(num_points, 1);
    for i = 1:num_points,
        x = xx(i) + 2;
        y = yy(i) + 2;
        
        centerV = 2*s(y,x);
        dXX = s(y,x-1) + s(y,x+1) - centerV;
        dYY = s(y+1,x) + s(y-1,x) - centerV;
        dXY = 0.25*(s(y+1,x+1) - s(y+1,x-1) - s(y-1,x+1) + s(y-1,x-1));
        
        TrH = dXX + dYY;
        DetH = dXX*dYY - dXY^2;
        
        if abs(TrH^2/DetH)<  tr
            valid(i) = true;
        end
    end
    
    xo = xx(valid,:);
    yo = yy(valid,:);
    vo = vv(valid,:);
end 

function [ xo, yo, so, angle, vo ] = compute_orientation (I, xx, yy, ss, v) 
    image_height = size(I, 1);
    image_width = size(I, 2);

    % Compute gradient
    dX = zeros(image_height, image_width);
    dY = zeros(image_height, image_width);
 
    dX(:,2:end-1) = I(:,3:end) - I(:,1:end-2);
    dY(2:end-1,:) = I(1:end-2,:) - I(3:end,:);
    grad = sqrt(dX.^2 + dY.^2);
    phi = atan2(dY,dX);
 
    % One bin is 10 degrees
    phi = round(phi*18/pi+18)+1;
    num_points = size(xx,1);
    p = 0;
    L = 36;

    for n = 1:num_points,
        h = zeros(round(36)+1,1);
        x = round(xx(n));
        y = round(yy(n));
        s = ss(n);

        sig = s*1.5;
        s = round(3.5*s);
        
        % Handle border cases
        if x - s < 1,
            xs = x - 1;
        else
            xs = s;
        end
        
        if y - s < 1,
            ys = y - 1;
        else
            ys = s;
        end
        if x + s > image_width,
            xe = image_width - x;
        else
            xe = s;
        end
        if y + s > image_height,
            ye = image_height - y;
        else
            ye = s;
        end
        
        % Build histogram
        for i = -ys:ye,
            for j = -xs:xe,
                h(phi(y+i,x+j)) = h(phi(y+i,x+j)) + grad(y+i,x+j)*exp(-(i^2+j^2)/2/sig^2); 
            end       
        end
        h(1) = h(1) + h(37); % Wrap-around
        h(37)=0;
 
        indt = find(h > 0.85*max(h));
        num_angles = size(indt,1);
   
        ii = 0;
        for i = 1:num_angles,
            if indt(i) == 1,
                if h(1) > h(2) && h(1) > h(L),
                    ii = ii + 1;
                    ind(ii) = indt(i);
               end
           elseif indt(i) == L,
               if h(L) > h(L-1) && h(L) > h(1),
                   ii = ii + 1;
                   ind(ii) = indt(i);
               end
            else
                if h(indt(i)) > h(indt(i)-1) && h(indt(i)) > h(indt(i)+1),
                   ii = ii + 1;
                   ind(ii) = indt(i);
                end
            end
        end
        
        num_angles = ii;
        
        for k = 1:num_angles,
            p = p + 1;
            x = (ind(k)-1) * 10;
           if ind(k) == 1,
                y1 = h(L);
                y2 = h(1);
                y3 = h(2); 
           elseif ind(k) == L,
                y1 = h(L-1); 
                y2 = h(L);
                y3 = h(1);
           else
                y1 = h(ind(k)-1);
                y2 = h(ind(k));
                y3 = h(ind(k)+1);
           end
       
            xo(p,1) = xx(n);
            yo(p,1) = yy(n);
            so(p,1) = ss(n);
            vo(p,1) = v(n);
            if y1 == y3,
                angle(p,1) = -x;
            else   
                angle(p,1) = -(x+5*(y1-y3)/(y1+y3-2*y2));
            end
        end
    end
end