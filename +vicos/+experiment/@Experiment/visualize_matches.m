function visualize_matches (self, I1, I2, kpts1, kpts2, match_idx, putative_matches, consistent_matches, varargin)
    % VISUALIZE_MATCHES (self, I1, I2, kpts1, kpts2, match_idx, putative_matches, consistent_matches, varargin)
    %
    % 
    
    parser = inputParser();
    parser.addParameter('pad', 10, @isnumeric);
    parser.addParameter('tikz_code_path', '', @ischar);
    parser.addParameter('caption_color', 'green', @ischar);
    parser.parse(varargin{:});
    
    hpad = parser.Results.pad;
    tikz_code_path = parser.Results.tikz_code_path;
    caption_color = parser.Results.caption_color;
    
    %% Gather correct-match pairings
    correct_matches = (consistent_matches == 1) & putative_matches;
    
    correct_match_idx = match_idx(correct_matches);
    kpts2 = kpts2(correct_matches); % Matches are test (kpts2) -> reference (kpts1)
    kpts1 = kpts1(correct_match_idx);
    
    num_correct_matches = sum(correct_matches);
    num_putative_matches = sum(putative_matches);
    
    %% Prepare output image
    h1 = size(I1, 1);
    w1 = size(I1, 2);
    c1 = size(I1, 3);
    
    h2 = size(I2, 1);
    w2 = size(I2, 2);
    c2 = size(I2, 3);
    
    ho = max(h1, h2);
    wo = w1 + hpad + w2;
    co = max(c1, c2);
    
    I = zeros(ho, wo, co, 'uint8');
    
    vpad1 = (ho - h1) / 2;
    vpad2 = (ho - h2) / 2;
    
    I(1+vpad1:vpad1+h1, 1:w1, :) = I1;
    I(1+vpad2:vpad2+h2, 1+hpad+w1:hpad+w1+w2, :) = I2;
    
    %% Compute coordinates in output image
    % Keypoint coordinates; C -> Matlab indexing
    pt1 = vertcat(kpts1.pt) + 1;
    pt2 = vertcat(kpts2.pt) + 1;
    
    % Offset the keypoints to account for paddings
    offset1 = [ 0, vpad1 ];
    offset2 = [ size(I1, 2) + hpad, vpad2 ];
    
    pt1 = bsxfun(@plus, offset1, pt1);
    pt2 = bsxfun(@plus, offset2, pt2);
    
    %% Create visualization
    if isempty(tikz_code_path)
        % Figure
        figure;
        imshow(I);
        hold on;
        
        line( [ pt1(:,1), pt2(:,1) ]', ...
            [ pt1(:,2), pt2(:,2) ]', 'color', 'green' );
        
        text_handle = text(0, 0, sprintf('Correct matches: %d', num_correct_matches), 'FontSize', 20, 'Color', caption_color);
        text_handle.Position(1) = 5;
        text_handle.Position(2) = text_handle.Extent(4)/2;
        
        text_handle = text(0, 0, sprintf('Precision: %.1f%%', 100*num_correct_matches/num_putative_matches), 'FontSize', 20, 'Color', caption_color);
        text_handle.Position(1) = wo - 5 - text_handle.Extent(3);
        text_handle.Position(2) = text_handle.Extent(4)/2;
        
        drawnow();
    else
        % Tikz output
        fig_height = 10; % Fix figure height (10cm), adjust width with aspect ratio
        fig_width = wo/ho * fig_height;
        
        x_min = 0.5;
        y_min = 0.5;
        x_max = wo + 0.5;
        y_max = ho + 0.5;

        caption_left_spec  = [ 'anchor=north west,text depth=0pt,font=\boldmath\fontsize{1.5cm}{1.75cm}\selectfont' ];
        caption_right_spec = [ 'anchor=north east,text depth=0pt,font=\boldmath\fontsize{1.5cm}{1.75cm}\selectfont' ];
        
        cm_text = sprintf('correct matches: %d', num_correct_matches);
        pr_text = sprintf('precision: \\SI{%.1f}{\\%%}', 100*num_correct_matches/num_putative_matches);
        
        % Load template
        template = fullfile(fileparts(mfilename('fullpath')), 'matches.tmpl.tex');
        template_str = fileread(template);
        
        % Substitute data
        template_str = strrep(template_str, '$$FIG_WIDTH$$', sprintf('%gcm', fig_width));
        template_str = strrep(template_str, '$$FIG_HEIGHT$$', sprintf('%gcm', fig_height));
        template_str = strrep(template_str, '$$X_MIN$$', sprintf('%g', x_min));
        template_str = strrep(template_str, '$$X_MAX$$', sprintf('%g', x_max));
        template_str = strrep(template_str, '$$Y_MIN$$', sprintf('%g', y_min));
        template_str = strrep(template_str, '$$Y_MAX$$', sprintf('%g', y_max));
        
        template_str = strrep(template_str, '$$CAPTION_LEFT$$', cm_text);
        template_str = strrep(template_str, '$$CAPTION_RIGHT$$', pr_text);
        
        template_str = strrep(template_str, '$$CAPTION_COLOR$$', caption_color);
        template_str = strrep(template_str, '$$CAPTION_LEFT_SPEC$$', caption_left_spec);
        template_str = strrep(template_str, '$$CAPTION_RIGHT_SPEC$$', caption_right_spec);
        
        if ~exist(tikz_code_path, 'dir')
            mkdir(tikz_code_path);
        end
        
        % Write output
        [ ~, basename ] = fileparts(tikz_code_path);
        output_filename = fullfile(tikz_code_path, [ basename, '.tex' ]);
        fid = fopen(output_filename, 'w+');
        fwrite(fid, template_str);
        fclose(fid);
        
        % Write image
        output_filename = fullfile(tikz_code_path, 'image.jpg');
        imwrite(I, output_filename);
        
        % Write correct matches data
        output_filename = fullfile(tikz_code_path, 'correct.txt');
        fid = fopen(output_filename, 'w+');
        for i = 1:size(pt1,1)
            fprintf(fid, '%g\t%g\n%g\t%g\n\n', pt1(i,1), pt1(i,2), pt2(i,1), pt2(i,2));
        end
        fclose(fid);
        
        % Write incorrect matches data
        output_filename = fullfile(tikz_code_path, 'incorrect.txt');
        fid = fopen(output_filename, 'w+');
        fclose(fid);
    end
end