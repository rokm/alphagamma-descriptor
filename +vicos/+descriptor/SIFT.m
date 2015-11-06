classdef SIFT < vicos.descriptor.OpenCvDescriptor
    % SIFT - OpenCV SURF descriptor extractor
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
    end
    
    methods
        function self = SIFT ()
            self.implementation = cv.DescriptorExtractor('SIFT');
        end
    end
end