classdef SIFT < vicos.descriptor.OpenCvDescriptor
    % SIFT - OpenCV SURF descriptor extractor
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
        
        patch_scale_factor = 10
    end
    
    methods
        function self = SIFT (varargin)
            % self = SIFT (varargin)
            %
            % Creates SIFT descriptor extractor.
            %
            % Input: optional key/value pairs that correspond directly to
            % the implementation's parameters:
            %  - NFeatures
            %  - NOctaveLayers
            %  - ConstrastThreshold
            %  - EdgeThreshold
            %  - Sigma
            %
            % Output:
            %  - @SIFT instance
            
            % Input parser
            parser = inputParser();
            parser.addParameter('NFeatures', [], @isnumeric);
            parser.addParameter('NOctaveLayers', [], @isnumeric);
            parser.addParameter('ConstrastThreshold', [], @isnumeric);
            parser.addParameter('EdgeThreshold', [], @isnumeric);
            parser.addParameter('Sigma', [], @isnumeric);  
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
            self.implementation = cv.DescriptorExtractor('SIFT', params{:});
        end
        
        function desc = compute_from_patch (self, I)
            % Keypoint position: center of the patch
            [ h, w, ~ ] = size(I);
            keypoint.pt = ([ w, h ] - 1) / 2;
            
            % Keypoint size: determined by patch_scale_factor parameter
            keypoint.size = size(I, 1) / self.patch_scale_factor;
            
            % Compute descriptor for the keypoint
            desc = self.compute(I, keypoint);
        end
    end
end