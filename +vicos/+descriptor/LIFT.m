classdef LIFT < vicos.descriptor.Descriptor
    % LIFT - LIFT keypoint descriptor
    %
    % This class uses vicos.misc.LiftWrapper class to implement LIFT
    % keypoint descriptor.
    %
    % K. M. Yi, E. Trulls, V. Lepetit, and P. Fua. "LIFT: Learned Invariant 
    % Feature Transform", European Conference on Computer Vision (ECCV), 2016.
    %
    % (C) 2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        wrapper
    end
    
    methods
        function self = LIFT (varargin)
            % self = LIFT (varargin)
            %
            % Creates LIFT descriptor.
            %
            % Input: optional key/value pairs:
            %
            % Output:
            %  - self:
            
            % Input parser
            parser = inputParser();
            parser.parse(varargin{:});
            
            % Create LIFT wrapper
            self.wrapper = vicos.misc.LiftWrapper();
        end
        
        function [ descriptors, keypoints ] = compute (self, I, keypoints)
            % Use wrapper
            [ descriptors, keypoints ] = self.wrapper.compute_lift_descriptors(I, keypoints);
        end
        
        function distances = compute_pairwise_distances (self, desc1, desc2)
            % Compute the distances using cv::batchDistance() and L2 norm; 
            % in order to get an N2xN1 matrix, we switch desc1 and desc2
            distances = cv.batchDistance(desc2, desc1, 'K', 0, 'NormType', 'L2');
        end
        
        function descriptor_size = get_descriptor_size (self)
            % Fixed-size
            descriptor_size = 128; % 128 floating-point values
        end
    end
    
    methods (Access = protected)
        function identifier = get_identifier (self)
            identifier = 'LIFT';
        end
    end
end