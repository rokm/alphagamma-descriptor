classdef OpenCvDescriptor < vicos.descriptor.Descriptor
    % OPENCVDESCRIPTOR - base class for OpenCV descriptor implementations
    %
    % (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties (Abstract)
        implementation
    end
    
    methods
        function self = OpenCvDescriptor (varargin)
            % self = OPENCVDESCRIPTOR (varargin)
            %
            % Base-class constructor for OpenCV descriptor extractor
            % implementations.
            %
            % Input: optional key/value pairs that are passed to
            % Descriptor constructor.
            %
            % Output:
            %  - self:
            
            self = self@vicos.descriptor.Descriptor(varargin{:});
        end
        
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
    
    methods (Static)
        function params = gather_parameters (parser, varargin)
            % params = GATHER_PARAMETRS (parser, varargin)
            %
            % Gathers non-default parameters from inputParser structure 
            % into a cell array containing key and value pairs, 
            % optionally ignoring specified field names.
            %
            % Input:
            %  - parser: inputParser structure after parsing is done
            %  - varargin: optional names of fields to ignore
            %
            % Output:
            %  - params: parameters with non-default values
            
            % Get list of non-default parameters
            names = setdiff(parser.Parameters, parser.UsingDefaults);
            
            % Remove the ones that we wish to explicitly ignore
            names = setdiff(names, varargin);
            
            % Gather into cell array
            params = cell(2, numel(names));
            for i = 1:numel(names)
                params{1, i} = names{i};
                params{2, i} = parser.Results.(names{i});
            end
            
            params = reshape(params, 1, []); % For the sake of consistency...
        end
    end
end