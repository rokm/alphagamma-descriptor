classdef SURF < vicos.descriptor.OpenCvDescriptor
    % SURF - OpenCV SURF descriptor extractor
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
    end
    
    methods
        function self = SURF ()
            self.implementation = cv.DescriptorExtractor('SURF');
        end
    end
end