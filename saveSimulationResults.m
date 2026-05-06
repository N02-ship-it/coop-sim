
function saveSimulationResults(DirectoryName, patternType, paramStrings, labelStrings, paramList, coopRateMeanByGen, coopRateStdByGen, coopRateByParamTrial, numGenerations)

splitParams = cellfun(@(x) strsplit(x), paramStrings, 'UniformOutput', false);
commonParts = splitParams{1};
for I = 2:numel(splitParams)
    commonParts = commonParts(ismember(commonParts, splitParams{I}));
end

LL = cell(size(paramStrings));
for I = 1:numel(paramStrings)
    parts = splitParams{I};
    parts = setdiff(parts, commonParts);
    LL{I} = strjoin(parts, ' ');
    LL{I} = regexprep(LL{I}, '\s*,\s*$', '');
    LL{I} = regexprep(LL{I}, '\s{2,}', ' ');
end

commonPartsStr = strjoin(commonParts, ' ');
invalidCharsPattern = '[^a-zA-Z0-9_-]';
cleanStr = regexprep(commonPartsStr, invalidCharsPattern, '');

timestamp = char(datetime('now','Format','yyyy-MM-dd_HH-mm-ss'));

FNAME = [DirectoryName '/' timestamp cleanStr patternType];
texFNAME = [DirectoryName '/' patternType];

save([FNAME '.mat']);


%%
fig1 = figure;
set(fig1, 'PaperUnits', 'inches', 'PaperSize', [6 4], 'PaperPosition', [0 0 6 4]);

ax1 = axes('Parent', fig1);
set(ax1, 'FontName', 'Times New Roman', 'FontSize', 12);

hold(ax1, 'on');
colors = lines(size(paramList,1));
line_handles = zeros(size(paramList,1),1);

for PP = 1:size(paramList,1)
    mean_rate = coopRateMeanByGen(:,PP);
    std_rate = coopRateStdByGen(:,PP);
    gen_vector = (1:numGenerations)';
    upper_bound = mean_rate + std_rate;
    lower_bound = mean_rate - std_rate;
    fill([gen_vector; flipud(gen_vector)], [upper_bound; flipud(lower_bound)], colors(PP,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    line_handles(PP) = plot(gen_vector, mean_rate, 'Color', colors(PP,:), 'LineWidth', 1.5);
end

hold off;
grid on;

xlim(ax1, [1 numGenerations]);
ylim(ax1, [0 1]);

xlabel(ax1, 'Generation',              'FontName', 'Times New Roman', 'FontSize', 12);
ylabel(ax1, 'Mutual Cooperation Rate', 'FontName', 'Times New Roman', 'FontSize', 12);

legend(line_handles, labelStrings, 'Interpreter', 'latex', 'Location', 'southeast');
saveas(fig1, [texFNAME '_t.pdf']);
saveas(fig1, [FNAME '.jpg']);
close(fig1);

%%
fig2 = figure;
set(fig2, 'PaperUnits', 'inches', 'PaperSize', [6 4], 'PaperPosition', [0 0 6 4]);
ax2 = axes('Parent', fig2);
set(ax2, 'FontName', 'Times New Roman', 'FontSize', 12);

hold(ax2, 'on');

dataGroups = coopRateByParamTrial';
numGroups = size(dataGroups, 2);
colors = lines(numGroups);
numPoints = 200; bandwidth = 0.1; scaleFactor = 0.5;
pointAlpha = 0.6; pointSize = 15;

for I = 1:numGroups
    data = dataGroups(:, I);
    y = linspace(min(data), max(data), numPoints);
    pdfVals = zeros(size(y));
    for j = 1:length(y)
        pdfVals(j) = sum(exp(-0.5*((y(j)-data)/bandwidth).^2)) / (length(data)*bandwidth*sqrt(2*pi));
    end
    pdfVals = pdfVals / max(pdfVals) * scaleFactor;
    fill([I - pdfVals, fliplr(I + pdfVals)], [y, fliplr(y)], colors(I,:), 'FaceAlpha', 0.3, 'EdgeColor', 'none');
    jitter = (rand(size(data)) - 0.5) * 0.2;
    scatter(I + jitter, data, pointSize, colors(I,:), 'filled', 'MarkerFaceAlpha', pointAlpha);
    plot([I I], [min(y) max(y)], 'k', 'LineWidth', 1);
end


xlim(ax2, [0.5, numGroups + 0.5]);
ylim(ax2, [0, 1]);

xticks(ax2, 1:numGroups);

ax2.XTickLabel = [];

for I = 1:numGroups
    str = labelStrings{I};
    baseFontSize = 12;
    maxLength = 10;
    scaleFactor = 0.2;

    fontSize = max(8, baseFontSize - scaleFactor * (length(str) - maxLength));

    text(I, ax2.YLim(1) - 0.05*(ax2.YLim(2)-ax2.YLim(1)), str, ...
        'Interpreter', 'latex', 'HorizontalAlignment', 'center', 'FontSize', fontSize);
end

ylabel(ax2,'Mutual Cooperation Rate', 'Interpreter', 'latex', 'FontSize', 12);
hold off;

saveas(fig2, [texFNAME '_v.pdf']);
saveas(fig2, [FNAME '_v.jpg']);

close(fig2);



%% ================================
% Multiple comparison (Wilcoxon + FDR)
% ================================

dataGroups = coopRateByParamTrial';  % [trial × condition]
numGroups  = size(dataGroups, 2);

pairResults = {};
pvals = [];
pairIdx = [];

idx = 0;
for i = 1:numGroups-1
    for j = i+1:numGroups
        idx = idx + 1;
        data_i = dataGroups(:, i);
        data_j = dataGroups(:, j);

        % Wilcoxon rank-sum test
        p = ranksum(data_i, data_j);

        pvals(idx) = p;
        pairIdx(idx, :) = [i, j];

        pairResults{idx, 1} = labelStrings{i};
        pairResults{idx, 2} = labelStrings{j};
        pairResults{idx, 3} = p;
    end
end

% ---- FDR correction (Benjamini–Hochberg) ----
pvals = pvals(:); 
[p_sorted, order] = sort(pvals);
m = length(pvals);
qvals = zeros(size(p_sorted));

for k = 1:m
   qvals(k) = p_sorted(k) * m / k;
end
qvals = min(qvals, 1);
qvals = flipud(cummin(flipud(qvals)));

% recover original order
qvals_corrected = zeros(size(qvals));
qvals_corrected(order) = qvals;

% qvals_corrected = mafdr(pvals, 'BHFDR', true);

%% ================================
% Display results in Command Window
% ================================

fprintf('\n=== Multiple Comparison Results (Wilcoxon + FDR) ===\n');
fprintf('%-20s %-20s %-12s %-12s\n', 'Condition A', 'Condition B', 'p-value', 'q-value');

for k = 1:m
    fprintf('%-20s %-20s %-.4e   %-.4e\n', ...
        pairResults{k,1}, pairResults{k,2}, pvals(k), qvals_corrected(k));
end

%% ================================
% Save multiple comparison results as TeX text (copy-paste ready)
% ================================

texTxtFile = [texFNAME '_mc.tex'];
fid = fopen(texTxtFile, 'w');

fprintf(fid, '\\begin{tabular}{llcc}\n');
fprintf(fid, '\\hline\n');
fprintf(fid, 'Condition A & Condition B & $p$-value & $q$-value \\\\\n');
fprintf(fid, '\\hline\n');

for k = 1:m
    condA = labelStrings{pairIdx(k,1)};
    condB = labelStrings{pairIdx(k,2)};
    fprintf(fid, '%s & %s & %.3e & %.3e \\\\\n', ...
        condA, condB, pvals(k), qvals_corrected(k));
end

fprintf(fid, '\\hline\n');
fprintf(fid, '\\end{tabular}\n');

fclose(fid);

descStats = cell(numGroups, 4);  % label, mean, std, median

for i = 1:numGroups
    data = dataGroups(:, i);
    descStats{i,1} = labelStrings{i};
    descStats{i,2} = mean(data);
    descStats{i,3} = std(data);
    descStats{i,4} = median(data);
end
texStatsFile = [texFNAME '_desc.tex'];
fid = fopen(texStatsFile, 'w');

fprintf(fid, '\\begin{tabular}{lccc}\n');
fprintf(fid, '\\hline\n');
fprintf(fid, 'Condition & Mean & Std. & Median \\\\\n');
fprintf(fid, '\\hline\n');

for i = 1:numGroups
    fprintf(fid, '%s & %.3f & %.3f & %.3f \\\\\n', ...
        descStats{i,1}, descStats{i,2}, descStats{i,3}, descStats{i,4});
end

fprintf(fid, '\\hline\n');
fprintf(fid, '\\end{tabular}\n');
fclose(fid);

end
