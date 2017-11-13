classdef RADIAL < vicos.keypoint_detector.KeypointDetector
    % RADIAL - RADIAL feature detector
    %
    % Improved RADIAL feature detector from:
    % J. Maver, "Self-similarity and points of interest," IEEE Transactions
    % on Pattern Analysis and Machine Intelligence, vol. 32, no. 7, 
    % pp. 1211-1226, 2010.
    
    properties
        max_features
        
        threshold
        
        num_scales
        min_scale
    end
    
    methods
        function self = RADIAL (varargin)
            % self = RADIAL (varagin)
            %
            % Creates RADIAL feature detector.
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
            parser.addParameter('Threshold', 0.62, @isnumeric);
            parser.addParameter('NumScales', 11, @isnumeric);
            parser.addParameter('MinScale', 5, @isnumeric);
            parser.addParameter('MaxFeatures', inf, @isnumeric);
            parser.parse(varargin{:});
            
            self = self@vicos.keypoint_detector.KeypointDetector(parser.Unmatched);
            
            self.threshold = parser.Results.Threshold;
            self.num_scales = parser.Results.NumScales;
            self.min_scale = parser.Results.MinScale;
            self.max_features = parser.Results.MaxFeatures;
        end
        
        function keypoints = detect (self, I)        
            keypoints = RADIALdetector(I, self.threshold, self.num_scales, self.min_scale, self.max_features);
        end
    end
    
    methods (Access = protected)
        function identifier = get_identifier (self)
            identifier = 'RADIAL';
        end
    end
end


%% Original code from Jasna
% TODO: cleanup, pre-compute filters, etc.
function keypoints = RADIALdetector(I, Threshold, NumScales, MinScale, MaxFeatureNum)   
    feature_r = [];
    keypoints = struct([]);
    
    % Handle 3-channel images
    if size(I, 3) == 3
        I = double(rgb2gray(I));
    else
        I = double(I);
    end
    filg = create_gaussian_filter(0.707);
    filg1 = create_gaussian_filter(1.6);
    filg2 = create_gaussian_filter(1.1);
    
    im1 = I;
    I = filter2(filg, I, 'same');
    
    %normalization constant
    %mmI = (max(max(I)));
    mmI=(mean(max(I,[],1))+mean(max(I,[],2))+max(max(I)))/3;
    %upsampling
    I = imresize(I, 2);
    %NumOctave: number of ''octaves''
    d = round(min(size(I)));
    NumOctave=1;
    while (d-1)/2 > (2*NumScales+2)
        NumOctave = NumOctave+1;
        d = d/2;
    end
    % we use only 3 "ocatves" '
    if NumOctave > 3
        NumOctave = 3;
    end
    
    %calculate filters or circles
    [filR,N] = filtriR(NumScales);
    
    for t = 1:NumOctave
        [ dim1, dim2 ] = size(I);
        % saliency maps
        s_r = zeros(dim1, dim2, NumScales);
        % average of a local region weight by (1/r)
        % and multplied by the number of samples
        av = zeros(dim1, dim2, NumScales);
        %NorStd are maps used for threshold
        NorStd = zeros(dim1, dim2, NumScales);
        I2 = I.^2;
        % We start with center point
        av(:,:,1) = filter2(filR{1},I,'same');
        x2 = filter2(filR{1},I2,'same');
        Csquare = av(:,:,1).^2;
        % calculation of saliency maps
        for r = 2:NumScales
            n = r*N; %number of samples
            %C: sum of itensity values on r-th circle
            C = filter2(filR{r}, I, 'same');
            % sum of squered intensity values
            x2 = x2 + filter2(filR{r}, I2, 'same');
            av(:,:,r) = av(:,:,r-1) + C;
            av2 = av(:,:,r).^2;
            Csquare = Csquare + C.^2;
            Cbetween=(Csquare-av2/r);
            s_r(:,:,r) = Cbetween./(x2-av2/n+eps)/N;
            %maps used for threshold
            NorStd(:,:,r) = (Cbetween/n/mmI/mmI);
            s_r(:,:,r)= filter2(filg1,s_r(:,:,r),'same');
        end
        %detect features and compute their orientation
        if t>1
            MinScale = 6;
        end
        
        feature_r = [feature_r; find_LSSM(MinScale,t,s_r,NorStd,Threshold,av)];
        
        %downsampling for new "octave"
        if t == 1
            I = im1;
            I= filter2(filg2,I,'same');
        else
            I = imresize(I, 0.5);
            I= filter2(filg,I,'same');
        end
    end
    
    %% Create output
    num_points = size(feature_r, 1);
    if num_points > MaxFeatureNum
        [~,ind]=sort(feature_r(:,4),'descend');
        feature_t=feature_r(ind,:);
        clear feature_r
        feature_r(1:MaxFeatureNum,:)=feature_t(1:MaxFeatureNum,:);
        num_points=MaxFeatureNum;
    end
    
    %    figure, imshow(im1,[]), hold on
    for p = 1:num_points
        keypoints(p).pt =( [ feature_r(p, 2), feature_r(p, 1) ]) - 1; %(x,y)
        %      plot( feature_r(p, 2),feature_r(p, 1),'xr')
        %      rectangle('Position',[feature_r(p, 2)-1/ feature_r(p, 3)/2-0.5, ...
        %      feature_r(p, 1)-1/ feature_r(p, 3)/2-0.5, 1/ feature_r(p, 3) + 1, 1/ feature_r(p, 3) + 1],'Curvature',[1 1],'EdgeColor','g')
        
        keypoints(p).size = 1/ feature_r(p, 3) + 1;
        keypoints(p).angle = feature_r(p, 5);
        keypoints(p).response = feature_r(p, 4);
        keypoints(p).octave = 0;
        keypoints(p).class_id = -1;
    end
    
end

function [feature]= find_LSSM(MinScale,t,s,NorStd,Threshold,av)
    %function [feature]= find_LSSM(MinScale,t,s,NorStd,Threshold,av,NS)
    %MinScale+1 is the min keypoint radius
    %t-2 tells how many times the input image was downsampled
    %s are saliency maps
    %Threshold  defines threshold on NorStd
    feature =[];
    M = size(s,3); %number of circles
    for sc = MinScale : M-1
        tr=Threshold^2;%-(sc-5)*0.005;
        
        tmp = s(sc+2:end-sc-1, sc+2:end-sc-1, sc);
        % maxima of the three levels
        ctm = max(NorStd(sc+2:end-sc-1,sc+2:end-sc-1,sc-1:sc+1), [], 3);
        % cm=NS(sc+2:end-sc-1,sc+2:end-sc-1,sc);
        v = max(s(sc+1:end-sc,sc+1:end-sc,sc-1:sc+1), [], 3);
        maxima = tmp >= v(2:end-1,1:end-2) & tmp >= v(2:end-1,3:end) & ...
            tmp >= v(1:end-2,2:end-1) & tmp >= v(3:end,2:end-1) & ...
            tmp >= v(1:end-2,1:end-2) & tmp >= v(1:end-2,3:end) & ...
            tmp >= v(3:end  ,1:end-2) & tmp >= v(3:end,3:end)   & ...
            tmp == v(2:end-1,2:end-1) & ctm >tr ;%& cm>0.003;
        [y_loc, x_loc] = find(maxima);
        v = ctm(maxima>0);
        %v = tmp(maxima>0); %for low contrast keypoints
        
        
        % abort bad extrema
        if size(x_loc,1) > 0
            [x_loc,y_loc,v] = goodExtrema(x_loc, y_loc, v, s(sc:end-sc+1, sc:end-sc+1, sc), 10.25);
            scale = ones(length(x_loc),1)*sc;
            %coordinates in s(:,:,sc)
            xn = x_loc + sc + 1;
            yn = y_loc + sc + 1;
            %compute orientation
            [xn,yn,scale,kot,v] = computeOrientation(av(:,:,sc), xn, yn, scale, v);
            rn = ones(size(xn,1),1) ./ ((scale-1).*2^(t-2)+0.5*2^(t-2));
            % descriptors with keypoint locations in input image
            feature = [feature; [yn*2^(t-2)+0.5*(1-2^(t-2)) , xn*2^(t-2)+0.5*(1-2^(t-2)) , rn, v, kot] ];
        end
    end
end

function[filR,NN]=filtriR(M)
    NN = 11*(M+1);  %number of sampling points on one circle
    N = 720;
    filR = cell(M,1);
    filR{1} = NN; %center point
    del=pi/N;
    for i = 2:M
        filT = zeros((i-1)*2+1, (i-1)*2+1);
        for j = 1:N
            r = i-1;
            x = i + round(r*cos(2*pi/N*(j-1)-del));
            y = i + round(r*sin(2*pi/N*(j-1)-del));
            filT(y,x) = filT(y,x) + 1;
        end
        nor=sum(sum(filT));
        filT=NN*filT/nor;
        filR{i} = filT;
    end
    %    figure, imshow(polje,[])
end

function[xo,yo,vo] = goodExtrema(xx,yy,vv,s,tr)
    fNum = size(xx,1);
    k = 0;
    xo = zeros(1,1);
    yo = zeros(1,1);
    vo = zeros(1,1);
    
    for i = 1:fNum
        %shift due to larger input saliency map
        x = xx(i) + 2;
        y = yy(i) + 2;
        centerV = 2 * s(y,x);
        dXX = s(y,x-1) + s(y,x+1) - centerV;
        dYY = s(y+1,x) + s(y-1,x) - centerV;
        dXY = (s(y+1,x+1) - s(y+1,x-1) - s(y-1,x+1) + s(y-1,x-1)) * 0.25;
        
        TrH = dXX + dYY;
        DetH = dXX * dYY - dXY^2;
        if abs(TrH^2/DetH) <  tr %good maximum
            k = k + 1;
            xo(k,1) = x - 2;
            yo(k,1) = y - 2;
            vo(k,1) = vv(i);
        end
    end
end

function[xo,yo,so,kot,vo]=computeOrientation(I,xx,yy,ss,v)
    [ dim1, dim2 ] = size(I);
    
    %image gradient
    dX = zeros(dim1,dim2);
    dY = zeros(dim1,dim2);
    dX(:,2:end-1) = I(:,3:end)-I(:,1:end-2);
    dY(2:end-1,:) = I(1:end-2,:)-I(3:end,:);
    Grad = sqrt(dX.^2+dY.^2);
    fi = atan2(dY,dX);
    
    %one bin includes 10 degrees, -pi[rd] is bin 1, pi[rd] is bin 37, at the end
    %moved to bin 1
    fi = round(fi*18/pi+18)+1;
    fNum = size(xx,1);
    
    p = 0;
    L = 36; %we have 36 + 1 bins
    for n = 1:fNum
        h = zeros(37,1);
        x = round(xx(n)); %x location
        y = round(yy(n)); %y location
        s = ss(n);        % scale
        sig = s*1.5; % gradient will be weighted with Gaussian filter
        s = round(3.5*s); % radius of a region we take gradiant from
        %for points near image border determine start and end index(index runs from -s to s)
        if x-s<1
            xs=x-1;
        else
            xs=s;
        end
        if y-s<1
            ys=y-1;
        else
            ys=s;
        end
        if x+s>dim2
            xe=dim2-x;
        else
            xe=s;
        end
        if y+s>dim1
            ye=dim1-y;
        else
            ye=s;
        end
        
        % histogram
        for i = -ys:ye
            for j = -xs:xe
                h(fi(y+i,x+j)) = h(fi(y+i,x+j))+Grad(y+i,x+j)*exp(-(i^2+j^2)/2/sig^2);
            end
        end
        h(1)=h(1)+h(37); %pi[rd] goes to -pi[rd]
        h(37)=0;
        
        %more than one orientation
        indt = find(h>0.8*max(h));
        %indt=find(h==max(h));
        NumKot = size(indt,1);
        ii = 0;
        for i = 1:NumKot
            if indt(i) == 1
                if h(1) > h(2) && h(1) > h(L)
                    %maximum at h(1)
                    ii = ii+1;
                    ind(ii) = indt(i);
                end
            elseif indt(i) == L
                if h(L) > h(L-1) && h(L) > h(1)
                    %maximum at h(L)
                    ii = ii+1;
                    ind(ii) = indt(i);
                end
            else
                if h(indt(i)) > h(indt(i)-1) && h(indt(i)) > h(indt(i)+1)
                    %maximum at h(indt(i))
                    ii=ii+1;
                    ind(ii)=indt(i);
                end
                
            end
        end
        NumKot = ii; %number of local maxima
        %rotation by interpolation
        for k = 1:NumKot
            p = p+1;
            x = 10*(ind(k)-1);
            if ind(k) == 1
                y1 = (h(L));
                y2 = (h(1));
                y3 = (h(2));
            elseif ind(k) == L
                y1 = (h(L-1));
                y2 = (h(L));
                y3 = (h(1));
            else
                y1 = (h(ind(k)-1));
                y2 = (h(ind(k)));
                y3 = (h(ind(k)+1));
            end
            
            xo(p,1)=xx(n);
            yo(p,1)=yy(n);
            so(p,1)=ss(n);
            vo(p,1)=v(n);
            if y1 == y3
                kot(p,1) = -x;
            else
                kot(p,1) = -(x+5*(y1-y3)/(y1+y3-2*y2));
            end
        end
    end
end

function filt = create_gaussian_filter (sigma)
    % Creates a Gaussian filter with specified sigma.
    
    sz = round(3*sigma);
    [ x, y ] = meshgrid(-sz:sz);
    filt = exp(-(x.^2/sigma^2 + y.^2/sigma^2)/2);
    filt = filt / sum(filt(:));
end
