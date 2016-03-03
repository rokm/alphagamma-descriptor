classdef FREAK < vicos.descriptor.OpenCvDescriptor
    % FREAK - OpenCV FREAK descriptor extractor
    %
    % (C) 2015-2016, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
        
        % The following should make use of the whole patch
        %patch_size = 24
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
            
            parser.addParameter('OrientationNormalized', [], @islogical);
            parser.addParameter('ScaleNormalized', [], @islogical);
            parser.addParameter('PatternScale', [], @isnumeric);
            parser.addParameter('NOctaves', [], @isnumeric);
            parser.addParameter('SelectedPairs', [], @isnumeric);
                        
            parser.parse(varargin{:});
            
            %% Gather parameters   
            fields = fieldnames(parser.Results);
            params = {};
            for f = 1:numel(fields),
                field = fields{f};
                if ~isempty(parser.Results.(field)),
                    params = [ params, field, parser.Results.(field) ];
                end
            end
            
            %% Create implementation
            self.implementation = cv.DescriptorExtractor('FREAK', params{:});
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
end