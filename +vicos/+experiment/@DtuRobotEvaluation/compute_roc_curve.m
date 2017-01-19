function [ roc, area ] = compute_roc_curve (ratios, correct)
    % [ roc, area ] = COMPUTE_ROC_CURVE (ratios, correct)
    %
    % Computes ROC curve and area under it.
    %
    % Input:
    %  - self:
    %  - ratio: Nx1 vector of descriptor distance ratios between
    %    first and second closest match
    %  - correct: Nx1 vector of flags indicating whether match is
    %    correct (1) or incorrect (-1)
    %
    % Output:
    %  - roc: ROC curve
    %  - area: area under ROC curve
    
    %% Store distance ratios for correct and incorrect matches
    scores = zeros(numel(ratios), 2);
    
    idx = correct == 1;
    scores(idx,1) = ratios(idx);
    
    idx = correct == -1;
    scores(idx,2) = ratios(idx);
    
    %% Compute ROC
    % Total number
    total = sum(scores > 0) + 1e-10;
    
    % Thresholds
    thresholds = 0.01:0.01:1;
    roc = zeros(numel(thresholds), 2);
    
    for i = 1:numel(thresholds)
        roc(i, 1) = sum(scores(:, 1) < thresholds(i) & scores(:,1) > 0) / total(1);
        roc(i, 2) = sum(scores(:, 2) > thresholds(i) & scores(:,2) > 0) / total(2);
    end
    
    %% Compute area under curve
    area = 0;
    for i = 2:size(roc,1)
        a = roc(i,1) - roc(i-1, 1);
        b = (roc(i,2) + roc(i-1, 2))/2;
        area = area + a*b;
    end
end