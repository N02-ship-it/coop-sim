
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

end
