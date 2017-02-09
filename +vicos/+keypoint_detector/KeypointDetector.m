classdef KeypointDetector < handle
    % KEYPOINTDETECTOR - base class for keypoint detector implementations
    %
    % (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties (Access = public)
        identifier
    end
    
    methods (Abstract)
        % keypoints = DETECT (self, I)
        %
        % Detect keypoints in the given image
        %
        % Input:
        %  - self:
        %  - I: image
        %
        % Output:
        %  - keypoints: array of OpenCV keypoint structures
        %
        keypoints = detect (self, I)
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
        function self = KeypointDetector (varargin)
            % self = KEYPOINTDETECTOR (varargin)
            %
            % Constructor of the base KeypointDetector class.
            %
            % Input: optional key/value pairs
            %  - identifier: optional identifier for keypoint detector to
            %    override the default implementation-provided identifier
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