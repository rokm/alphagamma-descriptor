classdef FeatureR7BW < vicos.keypoint_detector.KeypointDetector
    % FEATURER7BW - Lite version of Jasna's Radial feature detector.
    
    properties
        threshold

        num_circles
        filters
    end
    
    methods
        function self = FeatureR7BW (varargin)
            parser = inputParser();
            
            parser.addParameter('Threshold', 2*4e+006, @isnumeric); % FIXME: How did we get this threshold value?
            parser.addParameter('NumCircles', 7, @isnumeric);
            parser.parse(varargin{:});
            
            self.threshold = parser.Results.Threshold;
            self.num_circles = parser.Results.NumCircles;
                        
            %% Generate filters
            M = self.num_circles; % num circles
            circle_step = 1;
            N = ceil(M*3*circle_step + 3);

            self.filters = cell(1, M);
            for j = 1:M,
                radius = (j-1)*circle_step;
                
                win_size = ceil(radius);
                filter_size = 1 + 2*win_size;
                filter_center = 1 + win_size;
                filter = zeros(filter_size, filter_size);
                
                for i = 1:N,
                    x = round( radius*cos(2*pi/N*(i-1)) );
                    y = round( radius*sin(2*pi/N*(i-1)) );
                    
                    filter(filter_center-y, filter_center+x) = filter(filter_center-y, filter_center+x) + 1;
                end
                
                self.filters{j} = filter;
            end
        end
        
        
        function keypoints = detect (self, I)
            %% Prepare the image
            if size(I, 3) == 3,
                I = rgb2gray(I);
            end
            I = double(I);
            
            M = self.num_circles;
            
            %% Compute the annuli
            I_avg = zeros(size(I));
            I_avg2 = zeros(size(I));
            
            for j = 1:M,
                If = conv2(I, self.filters{j}, 'same');
                I_avg = I_avg + If;
                I_avg2 = I_avg2 + If.^2;
            end
            
            S_r = M*I_avg2 - I_avg.^2;
            
            %% Averaging filter
            average_filter = ones(3,3);
            average_filter = average_filter / sum(average_filter(:));
            
            S_r = conv2(S_r, average_filter, 'same');
            %S_r = conv2(S_r, average_filter, 'same');
                        
            %% Find local maxima
            tmp = S_r(2:end-1,2:end-1); % Skip out 1 pixel 
            
            P = zeros(size(S_r)); % Peaks image
            
            mask = tmp >= S_r(1:end-2,1:end-2) & ... % (-1,-1)
                   tmp >= S_r(2:end-1,1:end-2) & ... % ( 0,-1)
                   tmp >= S_r(3:end-0,1:end-2) & ... % (+1,-1)
                   tmp >= S_r(1:end-2,2:end-1) & ... % (-1, 0)
                   tmp >= S_r(3:end-0,2:end-1) & ... % (+1, 0)
                   tmp >= S_r(1:end-2,3:end-0) & ... % (-1,+1)
                   tmp >= S_r(2:end-1,3:end-0) & ... % ( 0,+1)
                   tmp >= S_r(3:end-0,3:end-0) & ... % (+1,+1)
                   tmp >= self.threshold; % Threshold
           
            % Substitute into our original matrix; cut off the border the
            % same way as the original code did...
            P(2+M:end-M-1,2+M:end-M-1) = mask(M+1:end-M,M+1:end-M);
            
            [ y, x ] = find(P);
            
            %% Create output
            num_points = numel(x);
            keypoints = repmat(struct('pt', [ 0, 0 ], 'size', 0, 'angle', 0, 'response', 0, 'octave', 0, 'class_id', 0), 1, num_points);
            
            for p = 1:num_points,
                keypoints(p).pt = [ x(p), y(p) ] - 1;
                keypoints(p).size = 2 * M + 1;
                keypoints(p).angle = 0;
                keypoints(p).response = 0; %S_r(y(p), x(p));
                keypoints(p).octave = 0;
                keypoints(p).class_id = -1;
            end
        end
    end
end
