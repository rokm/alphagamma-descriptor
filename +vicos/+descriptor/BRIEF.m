classdef BRIEF < vicos.descriptor.OpenCvDescriptor
    % BRIEF - OpenCV BRIEF descriptor extractor
    %
    % (C) 2015, Rok Mandeljc <rok.mandeljc@fri.uni-lj.si>
    
    properties
        implementation
    end
    
    methods
        function self = BRIEF (varargin)
            % self = BRIEF (varargin)
            %
            % Creates BRIEF descriptor extractor.
            %
            % Input: optional key/value pairs that correspond directly to
            % the implementation's parameters:
            %  - Bytes
            %  - UseOrientation
            %
            % Output:
            %  - @BRIEF instance
            
            % Input parser
            parser = inputParser();
            parser.addParameter('Bytes', [], @isnumeric);
            parser.addParameter('UseOrientation', [], @islogical);  
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
            self.implementation = cv.DescriptorExtractor('BriefDescriptorExtractor', params{:});
        end
        
        function desc = compute_from_patch (self, I)            
            % BRIEF implementation used 48x48 patch and 9x9 smoothing
            % kernel, thus it filters out points that are less than 
            % 24 + 4 = 28 pixels from the image border. Hence, the patch 
            % must be larger than 56x56 pixels, and we opt to use 58x58.
            I = imresize(I, [ 58, 58 ]);
            
            keypoint.pt = size(I) / 2;
            keypoint.size = size(I, 1) / 2;
            
            desc = self.compute(I, keypoint);
        end
    end
end