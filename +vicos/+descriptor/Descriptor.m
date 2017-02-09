classdef Descriptor < handle
    % DESCRIPTOR - base class for keypoint detector implementations
    %
    % (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties (Access = public)
        identifier
    end
    
    methods (Abstract)
        % [ descriptors, keypoints ] = COMPUTE (self, I, keypoints)
        %
        % Extracts descriptors from the specified keypoints in the given
        % image.
        %
        % NOTE: the implementation may decide to remove some of the
        % keypoints, or add new keypoints. Therefore, in addition to the
        % computed descriptors, the array of corresponding keypoints is
        % also returned by this method.
        %
        % Input:
        %  - self: @Descriptor instance
        %  - I: image
        %  - keypoints: 1xN array keypoints
        %
        % Output:
        %  - descriptors: MxD matrix of descriptors
        %  - keypoints: 1xM array of keypoints        
        [ descriptors, keypoints ] = compute (self, I, keypoints)
        
        % descriptor = COMPUTE_FROM_PATCH (self, I)
        %
        % Extracts a descriptor from the input patch. 
        %
        % Input:
        %  - self: @Descriptor instance
        %  - I: input patch
        %
        % Output:
        %  - descriptor: 1xD descriptor vector
        decriptor = compute_from_patch (self, I)
        
        % descriptor_size = GET_DESCRIPTOR_SIZE (self)
        %
        % Returns the size of descriptor.
        %
        % Input:
        %  - self: @Descriptor instance
        %
        % Output:
        %  - descriptor_size: descriptor size (in elements, not bytes!)
        descriptor_size = get_descriptor_size (self)
        
        % distances = COMPUTE_PAIRWISE_DISTANCES (self, desc1, desc2)
        %
        % Computes a matrix of pair-wise distances between two sets of
        % keypoint descriptors.
        %
        % Input:
        %  - self: @Descriptor instance
        %  - desc1: N1xD matrix of descriptors for first set of keypoints
        %  - desc2: N2xD matrix of descriptors for second set of keypoints
        %
        % Output:
        %  - distances: N2xN1 matrix of pair-wise distances between
        %    descriptors. Each column corresponds to a descriptor from the
        %    first set, and eeach row corresponds to a descriptor from the
        %    second set
        distances = compute_pairwise_distances (self, desc1, desc2)
    end
    
    methods (Abstract, Access = protected)
        % identifier = GET_IDENTIFIER (self)
        %
        % Obtains default implementation-provided identifier. This method
        % is intended for internal use; to obtain the actual identifier,
        % use the identifier property, which allows user-provided ovrride.
        %
        % Input:
        %  - self:
        %
        % Output:
        %  - identifier: identifier string
        identifier = get_identifier (self)
    end
    
    methods
        function self = Descriptor (varargin)
            % self = DESCRIPTOR (varargin)
            %
            % Constructor of the base Descriptor class.
            %
            % Input: optional key/value pairs
            %  - identifier: optional identifier for descriptor extractor
            %    to override the default implementation-provided identifier
            %
            % Output:
            %  - self:
            parser = inputParser();
            parser.addParameter('identifier', '', @ischar);
            parser.parse(varargin{:});
            
            self.identifier = parser.Results.identifier;
        end
        
        % Getter for identifier property
        function value = get.identifier (self)
            value = self.identifier; % User-provided value
            if isempty(value)
                value = self.get_identifier(); % Implementation-provided value
            end
        end
    end
end