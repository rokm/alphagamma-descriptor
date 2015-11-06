classdef LATCH < vicos.descriptor.OpenCvDescriptor
    % LATCH - OpenCV BRIEF descriptor extractor
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
    end
    
    methods
        function self = LATCH ()
            self.implementation = cv.DescriptorExtractor('LATCH');
        end
    end
end