classdef WebcamEvaluation < vicos.experiment.AffineEvaluation
    methods
        function self = WebcamEvaluation (varargin)
            parser = inputParser();
            parser.KeepUnmatched = true;
            parser.addParameter('dataset_path', '', @ischar);
            parser.parse(varargin{:});
            
            % Default dataset path
            dataset_path = parser.Results.dataset_path;
            if isempty(dataset_path)
                % Determine code root path
                code_root = fileparts(mfilename('fullpath'));
                code_root = fullfile(code_root, '..', '..', '..');
                dataset_path = fullfile(code_root, '..', 'datasets', 'webcam');
            end
            
            params = parser.Unmatched;
            params.dataset_path = dataset_path; % Add dataset path (properly overriden now)
            
            self = self@vicos.experiment.AffineEvaluation(params);
        end
        
        results = run_experiment (self, keypoint_detector, descriptor_extractor, sequence, varargin)
        
        % List all sequences
        sequences = list_all_sequences (self)
    end
end

