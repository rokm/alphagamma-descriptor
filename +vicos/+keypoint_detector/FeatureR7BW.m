classdef FeatureR7BW < vicos.keypoint_detector.KeypointDetector
    % FEATURER7BW - TODO
    
    properties
        threshold = 0.3
        min_scale = 3
        num_scales = 7
    end
    
    methods
        function self = FeatureR7BW (varargin)
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
            
            K=1;
            img = double(I);
            M = 7;
            MM = ceil(M*K);
            % N is the number of circular sectors in a local region
            N = ceil(K*3*M+3);
            %coordinates computes locations belonging to individual circle 
            %and circual sector
            [xCor,yCor]=locations(M,N,K);

            [dim1,dim2]=size(img);
            im=zeros(dim1+2*MM,dim2+2*MM);
            im(MM+1:MM+dim1,MM+1:MM+dim2)=img;

            % inicialization for annuli   
            n_average_x=N*im(MM+1:end-MM,MM+1:end-MM);
            n_average_x2=n_average_x.^2;
            xyc=n_average_x2;
            % anulli
            for r=2:M
                sum_st=zeros(dim1,dim2);
                for kk=1:N    
                    sum_st=sum_st+im(MM+1+yCor(r,kk):end-MM+yCor(r,kk),MM+1+xCor(r,kk):end-MM+xCor(r,kk));
                end
                n_average_x=n_average_x+sum_st;
                xyc=xyc+sum_st.^2;
            end 
            n_average_x2=n_average_x.^2;
            s_r=(M*xyc-n_average_x2);
            s_r=averaging(s_r);
            s_r=averaging(s_r);
            %tr=127070802/20;
            %tr=0.4e+006; %% GRAFFITI
            tr=2*4e+006;
            %feature location
            tmp = s_r(M+2:end-M-1, M+2:end-M-1);
            v = s_r(M+1:end-M,M+1:end-M);
            maxima = tmp >= v(2:end-1,1:end-2) & tmp >= v(2:end-1,3:end) & ...
                     tmp >= v(1:end-2,2:end-1) & tmp >= v(3:end,2:end-1) & ...
                     tmp >= v(1:end-2,1:end-2) & tmp >= v(1:end-2,3:end) & ...
                     tmp >= v(3:end  ,1:end-2) & tmp >= v(3:end,3:end)   & ...
                     tmp == v(2:end-1,2:end-1) & tmp> tr;
            [y_loc, x_loc] = find(maxima);
            v = tmp(maxima>0);
            feature_r = [(y_loc+1+M)*1 , (x_loc +1+M)*1 , ones(length(x_loc),1)/(M*1), v];

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

function[xCor,yCor]=locations(M,N,K)
%M is the nuber of annuli
%N is the number of circular sectors
xCor=zeros(M,N);
yCor=zeros(M,N);
xCor(1,:)=0;
yCor(1,:)=0;
for j=2:M   
    for i=1:N
        %x=r*cosf; y=r*sinf;
         x=round((j*K-1)*cos(2*pi/N*(i-1)));
         y=round((j*K-1)*sin(2*pi/N*(i-1)));
         xCor(j,i)=x;
         yCor(j,i)=-y;
    end
end
end