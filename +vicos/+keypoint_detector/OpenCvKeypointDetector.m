classdef OpenCvKeypointDetector < vicos.keypoint_detector.KeypointDetector
    % OPENCVKEYPOINTDETECTOR - base class for OpenCV keypoint detector implementations
    %
    % (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties (Abstract)
        % Provided by child via cv::featureDetector()
        implementation
    end
    
    methods
        function self = OpenCvKeypointDetector (varargin)
            % self = OPENCVKEYPOINTDETECTOR (varargin)
            %
            % Base-class constructor for OpenCV keypoint detector
            % implementations.
            %
            % Input: optional key/value pairs that are passed to
            % KeypointDetector constructor.
            %
            % Output:
            %  - self:
            
            self = self@vicos.keypoint_detector.KeypointDetector(varargin{:});
        end
        
        function keypoints = detect (self, I)
            % Detect keypoints using the child-provided implementation
            keypoints = self.implementation.detect(I);
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