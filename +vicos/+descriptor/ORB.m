classdef ORB < vicos.descriptor.OpenCvDescriptor
    % ORB - OpenCV ORB descriptor extractor
    %
    % (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
        
        % The following should make use of the whole patch
        patch_size = 24
    end
    
    methods
        function self = ORB (varargin)
            % self = ORB (varargin)
            %
            % Creates ORB descriptor extractor.
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
            %
            % Output:
            %  - @ORB instance
            
           % Input parser
            parser = inputParser();
            parser.KeepUnmatched = true;            
            parser.addParameter('MaxFeatures', [], @isnumeric);
            parser.addParameter('ScaleFactor', [], @isnumeric);
            parser.addParameter('NLevels', [], @isnumeric);
            parser.addParameter('FirstLevel', [], @isnumeric);
            parser.addParameter('WTA_K', [], @isnumeric);
            parser.addParameter('ScoreType', [], @(x) ismember(x, { 'Harris', 'FAST' }));
            parser.addParameter('PatchSize', [], @isnumeric);
            parser.addParameter('FastThreshold', [], @isnumeric);
            parser.parse(varargin{:});
            
            self = self@vicos.descriptor.OpenCvDescriptor(parser.Unmatched);
            
            %% Create implementation
            params = self.gather_parameters(parser);
            self.implementation = cv.DescriptorExtractor('ORB', params{:});
        end
        
        function desc = compute_from_patch (self, I)
            % Keypoint position: center of the patch
            [ h, w, ~ ] = size(I);
            keypoint.pt = ([ w, h ] - 1) / 2;
            
            % Keypoint size: determined by patch_scale_factor parameter
            keypoint.size = 10; %size(I, 1);% / self.patch_size;
            
            keypoint.class_id = 1;
            
            % Compute descriptor for the keypoint
            desc = self.compute(I, keypoint);
        end
    end
    
    methods (Access = protected)
        function identifier = get_identifier (self)
            identifier = 'ORB';
        end
    end
end