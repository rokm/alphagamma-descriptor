classdef FeatureRadial < vicos.keypoint_detector.KeypointDetector
    % FEATURERADIAL - TODO
    
    properties
        threshold = 0.3
        min_scale = 3
        num_scales = 7
    end
    
    methods
        function self = FeatureRadial (varargin)
            parser = inputParser();
            
            parser.addParameter('Threshold', 0.3, @isnumeric);
            parser.addParameter('NumScales', 7, @isnumeric);
            parser.addParameter('MinScale', 3, @isnumeric);
            parser.parse(varargin{:});
            
            self.threshold = parser.Results.Threshold;
            self.num_scales = parser.Results.NumScales;
            self.min_scale = parser.Results.MinScale;
        end
        
        
        function keypoints = detect (self, I)
       
            % Handle 3-channel images
            if size(I, 3) == 3,
                I = rgb2gray(I);
            end
            
            %% Original implementation
            img = double(I);
            M = self.num_scales;
            
            % N is the number of circular sectors in a local region
            %N=round(2.2*pi*M);
            N = round(3*M + 2);

            % coordinates computes locations belonging to individual circle 
            % and circual sector
            [ x_r, y_r, w, x_c, y_c ] = coordinates(M,N);

            [ dim1, dim2 ] = size(img);
            s_r = zeros(dim1, dim2, M+1);
            total_ss = zeros(dim1, dim2, M+1);
            err = ones(dim1, dim2)*0.0000000000001;
            im = zeros(dim1+2*M, dim2+2*M);
            im(M+1:M+dim1, M+1:M+dim2) = img;
            im2 = im.^2;
            sum_st = zeros(dim1, dim2);
            sum_st2 = zeros(dim1, dim2);

            % inicialization for annuli
            wa = w{1};
            x = x_c{1};
            y = y_c{1};
            dim = size(wa);
            for kk = 1:dim,
                sum_st = sum_st + wa(kk)*im(M+1+y(kk):end-M+y(kk),M+1+x(kk):end-M+x(kk));
                sum_st2 = sum_st2 + wa(kk)*im2(M+1+y(kk):end-M+y(kk),M+1+x(kk):end-M+x(kk));
            end

            n_average_x = sum_st;
            n_average_x2 = n_average_x.^2;
            x_2 = sum_st2;
            xyc = n_average_x2;
            
            % anulli
            for r = 2:M,
                n=r*N;
                wa=w{r};
                x=x_c{r};
                y=y_c{r};
                dim=size(wa);
                sum_st=zeros(dim1,dim2);
                sum_st2=zeros(dim1,dim2);
                for kk=1:dim    
                    sum_st=sum_st+wa(kk)*im(M+1+y(kk):end-M+y(kk),M+1+x(kk):end-M+x(kk));
                    sum_st2=sum_st2+wa(kk)*im2(M+1+y(kk):end-M+y(kk),M+1+x(kk):end-M+x(kk));
                end
                x_2=x_2+sum_st2;
                n_average_x=n_average_x+sum_st;
                n_average_x2=n_average_x.^2;
                xyc=xyc+sum_st.^2;
                total_ss(:,:,r)=(x_2-n_average_x2/n)+err;

                s_r(:,:,r)=(xyc-n_average_x2/r)./total_ss(:,:,r)/N;   
                total_ss(:,:,r)=total_ss(:,:,r)/N/r;
                s_r(:,:,r)=averaging(s_r(:,:,r));
            end
            
            R_min = self.min_scale;

            feature_r = find_LSSM(R_min,1,s_r,total_ss,self.threshold);

            %% Create output
            num_points = size(feature_r, 1);
            for p = 1:num_points,
                keypoints(p).pt = [ feature_r(p, 2), feature_r(p, 1) ] - 1;
                keypoints(p).size = 2 / feature_r(p, 3) + 1;
                keypoints(p).angle = 0;
                keypoints(p).response = 0;%feature_r(p, 4);
                keypoints(p).octave = 0;
                keypoints(p).class_id = 0;
            end
        end
    end
end

function [feature]= find_LSSM(R_min,t,s,variance,tr)
    %R_min+1 is the radius of the smallest feature
    %t-1 tells how many times the input image was downsampled
    %s are saliency maps
    %variance is the variance of a local region
    %tr defines threshold for saliency
    %s=round(s*10000);
    %s=s/10000;
    feature =[];
    M=size(s,3);
    yes=0;

    for sc=R_min:M-1
        tmp = s(sc+2:end-sc-1, sc+2:end-sc-1, sc);
        ct = sqrt(variance(sc+2:end-sc-1, sc+2:end-sc-1,sc));
       % maxima of the three levels
        v = max(s(sc+1:end-sc,sc+1:end-sc,sc-1:sc+1), [], 3);
        %v=s(sc+1:end-sc,sc+1:end-sc,sc);
        maxima = tmp >= v(2:end-1,1:end-2) & tmp >= v(2:end-1,3:end) & ...
                 tmp >= v(1:end-2,2:end-1) & tmp >= v(3:end,2:end-1) & ...
                 tmp >= v(1:end-2,1:end-2) & tmp >= v(1:end-2,3:end) & ...
                 tmp >= v(3:end  ,1:end-2) & tmp >= v(3:end,3:end)   & ...
                 tmp == v(2:end-1,2:end-1) & ct >7 & tmp> tr;
        [y_loc, x_loc] = find(maxima);

        v = tmp(maxima>0);
        f = [(y_loc+1+sc)*2^(t-1) , (x_loc +1+sc)*2^(t-1) , ones(length(x_loc),1)*1/((sc-1)*2^(t-1)), v];
        feature = [feature ; f];
    end
    if yes==1
    sc=M;
    tmp = s(sc+2:end-sc-1, sc+2:end-sc-1, sc);
        ct = sqrt(variance(sc+2:end-sc-1, sc+2:end-sc-1,sc));
       % maxima of the three levels
        v = max(s(sc+1:end-sc,sc+1:end-sc,sc-1:sc), [], 3);
        %v=s(sc+1:end-sc,sc+1:end-sc,sc);
        maxima = tmp >= v(2:end-1,1:end-2) & tmp >= v(2:end-1,3:end) & ...
                 tmp >= v(1:end-2,2:end-1) & tmp >= v(3:end,2:end-1) & ...
                 tmp >= v(1:end-2,1:end-2) & tmp >= v(1:end-2,3:end) & ...
                 tmp >= v(3:end  ,1:end-2) & tmp >= v(3:end,3:end)   & ...
                 tmp == v(2:end-1,2:end-1) & ct >7 & tmp> tr;
        [y_loc, x_loc] = find(maxima);

        v = tmp(maxima>0);
        f = [(y_loc+1+sc)*2^(t-1) , (x_loc +1+sc)*2^(t-1) , ones(length(x_loc),1)*1/((sc-1)*2^(t-1)), v];
        feature = [feature ; f];
    end
end

function[sls] = averaging(im)
%average of 9 neighboring pixels
    im = double(im);
    [d1,d2]=size(im);
    vect=zeros(d1+2,d2+2);
    vect(2:1+d1,2:d2+1)=im;
    sls=1/9*(vect(2:end-1,2:end-1)+...
        vect(1:end-2,2:end-1)+vect(3:end,2:end-1)+vect(2:end-1,1:end-2)+vect(2:end-1,3:end)+...
        vect(1:end-2,1:end-2)+vect(3:end,1:end-2)+vect(3:end,3:end)+vect(1:end-2,3:end));
end

function [x_r,y_r,w,x_c,y_c] = coordinates (M,N)
    %M is the nuber of annuli
    %N is the number of circular sectors

    x_r=zeros(M,N);
    y_r=zeros(M,N);

    %inicialization for annuli
    y_c{1}=0;
    x_c{1}=0;
    w{1}=N;
    %inicialization for circular sectors
    y_r(1,1:N)=0; 
    x_r(1,1:N)=0;

    for j=2:M   
        d=j;
        polje=zeros(2*d+1,2*d+1);
        c=d+1;
        for i=1:N
            %x=r*cosf; y=r*sinf;
             x=round((j-1)*cos(2*pi/N*(i-1)));
             y=round((j-1)*sin(2*pi/N*(i-1)));
             % interpolation 
             polje(c-y,c+x)=polje(c-y,c+x)+1;
             y_r(j,i)=-y;
             x_r(j,i)=x;
        end

        [y_t,x_t]=find(polje>0);
        y_c{j}=y_t-c;
        x_c{j}=x_t-c;
        w{j}=polje(polje>0);
    end
end