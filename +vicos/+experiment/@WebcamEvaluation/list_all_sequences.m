function sequences = list_all_sequences (self)
    % sequences = LIST_ALL_SEQUENCES (self)
    %
    % List all sequences in the dataset path.
    %
    % Input:
    %  - self:
    %
    % Output:
    %  - sequences: cell array of supported sequence names
    
    % List contents of dataset path
    contents = dir(self.dataset_path);
    
    % Mask directories (that are not . or ..)
    mask = ~ismember({ contents.name }, { '.', '..' }) & [ contents.isdir ];
    sequence_dirs = contents(mask);
    
    sequences = { sequence_dirs.name };
end