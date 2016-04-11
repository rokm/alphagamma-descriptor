classdef ORB < vicos.keypoint_detector.OpenCvKeypointDetector
    % ORB - OpenCV ORB keypoint detector
    %
    % (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation

        upright
    end
    
    methods
        function self = ORB (varargin)
            % self = ORB (varargin)
            %
            % Creates ORB keypoint detector.
            %
            % Input: optional key/value pairs that correspond directly to
            % the implementation's parameters:
            %  - MaxFeatures
            %  - ScaleFactor
            %  - NLevels
            %  - FirstLevel
            %  - WTA_K
            %  - ScoreType
            %  - PatchSize
            %  - FastThreshold
            %  - UpRight: manually zero the angles returned by the detector
            %
            % Output:
            %  - @ORB instance
            
            % Input parser
            parser = inputParser();
            parser.addParameter('MaxFeatures', [], @isnumeric);
            parser.addParameter('ScaleFactor', [], @isnumeric);
            parser.addParameter('NLevels', [], @isnumeric);
            parser.addParameter('FirstLevel', [], @isnumeric);
            parser.addParameter('WTA_K', [], @isnumeric);
            parser.addParameter('ScoreType', [], @(x) ismember(x, { 'Harris', 'FAST' }));
            parser.addParameter('PatchSize', [], @isnumeric);
            parser.addParameter('FastThreshold', [], @isnumeric);
            parser.addParameter('UpRight', false, @islogical);
            parser.parse(varargin{:});

            self.upright = parser.Results.UpRight;

            %% Gather parameters   
            fields = fieldnames(parser.Results);
            fields = setdiff(fields, 'UpRight'); % exclude
            params = {};
            for f = 1:numel(fields),
                field = fields{f};
                if ~isempty(parser.Results.(field)),
                    params = [ params, field, parser.Results.(field) ];
                end
            end
            
            %% Create implementation
            self.implementation = cv.FeatureDetector('ORB', params{:});
        end
        
        function keypoints = detect (self, I)
            % Detect keypoints using the child-provided implementation
            keypoints = self.implementation.detect(I);
            
            if self.upright,
                [ keypoints.angle ] = deal(0);
            end
        end
    end
end