classdef RootSIFT < vicos.descriptor.SIFT
    % RootSIFT - RootSIFT descriptor extractor
    %
    % (C) 2017, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    methods
        function self = RootSIFT (varargin)
            % self = RootSIFT (varargin)
            %
            % Creates RootSIFT descriptor extractor.
            %
            % Input: optional key/value pairs that correspond directly to
            % the underlying SIFT implementation's parameters:
            %  - NFeatures
            %  - NOctaveLayers
            %  - ConstrastThreshold
            %  - EdgeThreshold
            %  - Sigma
            %
            % Output:
            %  - @RootSIFT instance
            
            % Input parser
            parser = inputParser();
            parser.KeepUnmatched = true;            
            parser.parse(varargin{:});

            self = self@vicos.descriptor.SIFT(parser.Unmatched);
            
            %% Create implementation           
            params = self.gather_parameters(parser);
            self.implementation = cv.DescriptorExtractor('SIFT', params{:});
        end
        
        function [ descriptors, keypoints ] = compute (self, I, keypoints)
            % [ descriptors, keypoints ] = COMPUTE (self, I, keypoints)
            
            % Compute SIFT descriptors
            [ descriptors, keypoints] = compute@vicos.descriptor.SIFT(self, I, keypoints);
            
            % Step 1: L1 normalization of feature vectors
            desc_l1 = sum(abs(descriptors), 2) + eps;
            descriptors = bsxfun(@rdivide, descriptors, desc_l1);
            
            % Step 2: element-wise square root
            descriptors = sqrt(descriptors);
        end
    end
    
    methods (Access = protected)
        function identifier = get_identifier (self)
            identifier = 'RootSIFT';
        end
    end
end