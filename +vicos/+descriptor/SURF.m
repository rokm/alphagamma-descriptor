classdef SURF < vicos.descriptor.OpenCvDescriptor
    % SURF - OpenCV SURF descriptor extractor
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
        
        % The following scale factor should theoretically make use of the 
        % whole patch
        patch_scale_factor = 1 / (9.0/1.2 * 1/(20+1))
    end
    
    methods
        function self = SURF (varargin)
            % self = SURF (varargin)
            %
            % Creates SURF descriptor extractor.
            %
            % Input: optional key/value pairs that correspond directly to
            % the implementation's parameters:
            %  - HessianThreshold
            %  - NOctaves
            %  - NOctaveLayers
            %  - Extended
            %  - Upright
            %
            % Output:
            %  - @SURF instance
            
            % Input parser
            parser = inputParser();
            parser.addParameter('HessianThreshold', [], @isnumeric);
            parser.addParameter('NOctaves', [], @isnumeric);
            parser.addParameter('NOctaveLayers', [], @isnumeric);
            parser.addParameter('Extended', [], @islogical);
            parser.addParameter('Upright', [], @islogical);  
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
            self.implementation = cv.DescriptorExtractor('SURF', params{:});
        end
        
        function desc = compute_from_patch (self, I)            
            % SURF implementation has a PATCH_SIZE constant of 20; when
            % computing descriptor, it takes the keypoint's size parameter,
            % and multiplies it by 1.2/9.0, and divides by (PATCH_SIZE+1)
            % to obtain the sampling window around the keypoint...
            
            keypoint.pt = size(I) / 2;
            keypoint.size = size(I, 1) / self.patch_scale_factor;
                        
            desc = self.compute(I, keypoint);
        end
    end
end