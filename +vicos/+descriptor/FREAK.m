classdef FREAK < vicos.descriptor.OpenCvDescriptor
    % FREAK - OpenCV FREAK descriptor extractor
    %
    % (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
        
        % The following should make use of the whole patch
        keypoint_size = 9
    end
    
    methods
        function self = FREAK (varargin)
            % self = FREAK (varargin)
            %
            % Creates FREAK descriptor extractor.
            %
            % Input: optional key/value pairs that correspond directly to
            % the implementation's parameters:
            %  - OrientationNormalized
            %  - ScaleNormalized
            %  - PatternScale
            %  - NOctaves
            %  - SelectedPairs
            % Output:
            %  - @FREAK instance
            
            % Input parser
            parser = inputParser();
            parser.KeepUnmatched = true;            
            parser.addParameter('OrientationNormalized', [], @islogical);
            parser.addParameter('ScaleNormalized', [], @islogical);
            parser.addParameter('PatternScale', [], @isnumeric);
            parser.addParameter('NOctaves', [], @isnumeric);
            parser.addParameter('SelectedPairs', [], @isnumeric);
            parser.parse(varargin{:});
            
            self = self@vicos.descriptor.OpenCvDescriptor(parser.Unmatched);

            %% Create implementation
            params = self.gather_parameters(parser);
            self.implementation = cv.DescriptorExtractor('FREAK', params{:});
        end
        
        function desc = compute_from_patch (self, I)            
            % When used with 'ScaleNormalized'=false, the minimum patch
            % size for which we can get the descriptor is 134 pixels. With
            % 'ScaleNormalized'=true, a 64x64 patch has a maximum keypoint
            % size of 9.68 (This is for stock FREAK implementation, which
            % discards points that are too close to the border)
            
            % Keypoint position: center of the patch
            [ h, w, ~ ] = size(I);
            keypoint.pt = ([ w, h ] - 1) / 2;
            
            % Keypoint size: determined by patch_scale_factor parameter
            keypoint.size = self.keypoint_size;
            
            keypoint.angle = 0;            
            keypoint.class_id = -1;
            
            % Compute descriptor for the keypoint
            desc = self.compute(I, keypoint);
        end
    end
    
    methods (Access = protected)
        function identifier = get_identifier (self)
            identifier = 'FREAK';
        end
    end
end