
function saveHeatmapResults(DirectoryName, axisInfo, patternType, paramStrings, paramList, cooperationRateResults, numGenerations)

splitParams = cellfun(@(x) strsplit(x), paramStrings, 'UniformOutput', false);
commonParts = splitParams{1};
for i = 2:numel(splitParams)
    commonParts = commonParts(ismember(commonParts, splitParams{i}));
end
commonPartsStr = strjoin(commonParts, '_');

invalidCharsPattern = '[^a-zA-Z0-9_-]';
cleanStr = regexprep(commonPartsStr, invalidCharsPattern, '');
if length(cleanStr) > 50
    cleanStr = cleanStr(1:50);
end

timestamp = char(datetime('now','Format','yyyy-MM-dd_HH-mm-ss'));
FNAME = [DirectoryName '/' timestamp cleanStr patternType];
texFNAME = [DirectoryName '/' patternType];

save([FNAME '.mat'], 'axisInfo', 'paramStrings', 'paramList', 'cooperationRateResults');

xIdx = axisInfo.xIdx; yIdx = axisInfo.yIdx;
xVals = axisInfo.xVals; yVals = axisInfo.yVals;

lastGen = numGenerations;
Zvec = mean(cooperationRateResults(:, lastGen, :), 3);   % [PP x 1]
[~, ~, Zmat] = reshapeToGridFromParamList(paramList, Zvec, xIdx, yIdx);

figH = figure('Color','w');
width = 6; height = 4; % inches
set(figH, 'PaperUnits', 'inches', 'PaperSize', [width height], 'PaperPosition', [0 0 width height]);

axH = axes('Parent', figH);
set(axH, 'FontName', 'Times New Roman', 'FontSize', 12)

imagesc(xVals, yVals, Zmat); axis xy;
colormap(parula); caxis([0 1]);
cb = colorbar;
cb.Label.String = 'Mutual Cooperation Rate';
cb.Label.FontSize = 12;
cb.Label.Interpreter = 'latex';
cb.Location = 'eastoutside';

xlabel(getLatexLabel(axisInfo.xParam), 'Interpreter', 'latex');
ylabel(getLatexLabel(axisInfo.yParam), 'Interpreter', 'latex');
% title(sprintf('Heatmap (Final Gen, TT mean)\n%s', cleanStr), 'Interpreter','latex');

grid on; set(gca,'FontSize',12);

saveas(figH, [texFNAME '.pdf']);
saveas(figH, [FNAME '.jpg']);
pause(2);
close(figH);
end


function label = getLatexLabel(paramName)
switch paramName
    case 'roundsPerMatch', label = '$R_{match}$ (Rounds per Match)';
    case 'matchesPerGen', label = '$M_{gen}$ (Matches per Generation)';
    case 'mutationRate', label = '$\mu$ (Mutation Rate)';
    case 'learningRate', label = '$\alpha$ (Learning Rate)';
    case 'appearanceRatio', label = 'Appearance Ratio';
    case 'appearanceBonus', label = '$\beta$ (Appearance Bonus)';
    otherwise, label = paramName;
end
end


function [xVals, yVals, ZMat] = reshapeToGridFromParamList(paramList, Zvec, xIdx, yIdx)
xVals = sort(unique(paramList(:, xIdx))).';
yVals = sort(unique(paramList(:, yIdx))).';
ZMat = nan(numel(yVals), numel(xVals));
for pp = 1:size(paramList,1)
    xv = paramList(pp, xIdx);
    yv = paramList(pp, yIdx);
    xi = find(abs(xVals - xv) < 1e-12, 1);
    yi = find(abs(yVals - yv) < 1e-12, 1);
    if ~isempty(xi) && ~isempty(yi)
        if isnan(ZMat(yi,xi))
            ZMat(yi,xi) = Zvec(pp);
        else
            ZMat(yi,xi) = (ZMat(yi,xi) + Zvec(pp)) / 2;
        end
    end
end
end
