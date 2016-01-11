classdef OpenCvDescriptor < vicos.descriptor.Descriptor
    % OPENCVDESCRIPTOR - base class for OpenCV descriptor implementations
    %
    % (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties (Abstract)
        implementation
    end
    
    methods
        function [ descriptors, keypoints ] = compute (self, I, keypoints)
            % Extract descriptors using the mexopencv wrapper
            [ descriptors, keypoints ] = self.implementation.compute(I, keypoints);
        end
        
        function descriptor_size = get_descriptor_size (self)
            % Query the implementation for descriptor size
            descriptor_size = self.implementation.descriptorSize();
        end
        
        function distances = compute_pairwise_distances (self, desc1, desc2)
            % Query the implementation for default norm type
            normType = self.implementation.defaultNorm();
            
            % Compute the distances using cv::batchDistance(); in order to
            % get an N2xN1 matrix, we switch desc1 and desc2
            distances = cv.batchDistance(desc2, desc1, 'K', 0, 'NormType', normType);
        end
    end
end