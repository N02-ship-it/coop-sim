function [paramList, paramStrings, labelStrings, axisInfo, patternType] = createParamList(kind)

base = struct( ...
    'numAgents',        10, ...
    'matchesPerGen',    10, ...
    'roundsPerMatch',   10, ...
    'learningRate',     0.20, ...
    'survivalRate',     0.50, ...
    'mutationRate',     0.01, ...
    'temperature',      0.01, ...
    'matchPattern',     0, ...
    'appearanceRatio',  0, ...
    'appearanceBonus',  0, ...
    'evolutionPattern', 1, ...
    'enableLearningRateEvolution', 0  ...
    );

grids = struct( ...
    'roundsVals',  [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20], ...
    'matchesVals', [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20], ...
    'muVals',      logspace(-3, -1, 10), ...     % μ: 8点（10^-3～10^-1）
    'alphaVals',   [0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5], ... 
    'appRatioVals', [0.1 0.2 0.3 0.4 0.5 0.6 0.7], ...
    'appBonusVals',  [1 2 3 4 5 6 7 8 9 10] ...
    );


switch char(kind)
    case {'Rm_Mg' 'mu_alpha' 'apps'}

        name2idx = struct( ...
            'numAgents',1,'matchesPerGen',2,'roundsPerMatch',3,'learningRate',4,'survivalRate',5,'mutationRate',6,'temperature',7, ...
            'matchPattern',8,'appearanceRatio',9,'appearanceBonus',10,'evolutionPattern',11,'enableLearningRateEvolution',12);

        switch char(kind)
            case 'Rm_Mg'
                xParam = 'roundsPerMatch'; yParam = 'matchesPerGen';
                xVals = grids.roundsVals; yVals = grids.matchesVals;

            case 'mu_alpha'
                xParam = 'mutationRate'; yParam = 'learningRate';
                xVals = grids.muVals; yVals = grids.alphaVals;

            case 'apps'
                xParam = 'appearanceRatio'; yParam = 'appearanceBonus';
                xVals = grids.appRatioVals; yVals = grids.appBonusVals;

            otherwise
                error('Unknown pattern "%s".', kind);
        end

        xIdx = name2idx.(xParam);
        yIdx = name2idx.(yParam);

        [paramList, paramStrings] = buildGrid(base, xIdx, xVals, yIdx, yVals);
        axisInfo = struct('kind',kind,'xParam',xParam,'xVals',xVals,'xIdx',xIdx,'yParam',yParam,'yVals',yVals,'yIdx',yIdx);
        patternType = kind;
        labelStrings =[];

    case {'numAgents','matchesPerGen','roundsPerMatch','learningRate','survivalRate','mutationRate','temperature','matchPattern','appearanceRatio','appearanceBonus','evolutionPattern','enableLearningRateEvolution'}
        name2idx = struct( ...
            'numAgents',1,'matchesPerGen',2,'roundsPerMatch',3,'learningRate',4,'survivalRate',5,'mutationRate',6,'temperature',7,'matchPattern',8,'appearanceRatio',9,'appearanceBonus',10,'evolutionPattern',11,'enableLearningRateEvolution',12);
        idx  = name2idx.(kind);

        tmpVals = defaultSingleVals(kind);
        vals    = tmpVals(:);

        if strcmp(kind, 'appearanceRatio')
            base.appearanceBonus = 1;
        elseif strcmp(kind, 'appearanceBonus')
            base.appearanceRatio = 0.2;
        end

        numPP = numel(vals);
        paramList    = zeros(numPP, 12);
        paramStrings = cell(numPP, 1);
        labelStrings = cell(numPP, 1);

        for i = 1:numPP
            p = fillBase(base);
            p(idx) = vals(i);
            paramList(i,:)    = p;
            paramStrings{i}   = makeLabelExact(p);

            labelStrings{i} = makeLabelSingle(idx, vals(i));

        end
        axisInfo    = [];
        patternType = char(kind);

    otherwise
        error('未知の指定 "%s" です。''mu_SR''、''Rm_Mg''、またはパラメータ名 ''N''|''NM_G''|''NIPD_M''|''Alpha''|''survivalRate''|''P_mut''|''T''|''MP''|''AR''|''beta''|''EP''|''enableAlphaEvolution'' を指定してください。', char(kind));
end
end

%%

function [paramList, paramStrings] = buildGrid(base, xIdx, xVals, yIdx, yVals)
[Xg, Yg] = ndgrid(xVals, yVals);
numPP = numel(Xg);
paramList    = zeros(numPP, 12);
paramStrings = cell(numPP, 1);
for i = 1:numPP
    p = fillBase(base);
    p(xIdx) = Xg(i);
    p(yIdx) = Yg(i);
    paramList(i,:)  = p;
    paramStrings{i} = makeLabelExact(p);
end
end


function p = fillBase(base)
% Fill parameter vector from base structure
p = zeros(1,12);
p(1)  = base.numAgents;                  % Number of agents
p(2)  = base.matchesPerGen;              % Matches per generation
p(3)  = base.roundsPerMatch;             % Rounds per match
p(4)  = base.learningRate;               % Learning rate
p(5)  = base.survivalRate;               % Survival rate
p(6)  = base.mutationRate;               % Mutation rate
p(7)  = base.temperature;                % Exploration temperature
p(8)  = base.matchPattern;               % Matching pattern
p(9)  = base.appearanceRatio;            % Enable appearance bonus (boolean)
p(10) = base.appearanceBonus;            % Appearance bonus weight
p(11) = base.evolutionPattern;           % Evolution pattern
p(12) = base.enableLearningRateEvolution;% Enable learning rate evolution
end



function s = makeLabelExact(p)
numAgents                  = p(1);
matchesPerGen              = p(2);
roundsPerMatch             = p(3);
learningRate               = p(4);
survivalRate               = p(5);
mutationRate               = p(6);
temperature                = p(7);
matchPatternVal            = p(8);
appearanceRatioVal         = p(9);
appearanceBonus            = p(10);
evolutionPattern           = p(11);
enableLearningRateEvolution= p(12);


% Convert numeric codes to descriptive strings
switch matchPatternVal
    case 0
        matchPatternStr = 'Random';
    case 1
        matchPatternStr = 'Optimistic-Max';
    case 2
        matchPatternStr = 'Optimistic-Min';
    case 3
        matchPatternStr = 'Pessimistic-Max';
    case 4
        matchPatternStr = 'Pessimistic-Min';
    otherwise
        matchPatternStr = sprintf('Pattern %d', matchPatternVal);
end

switch evolutionPattern
    case 1
        evolutionPatternStr = 'Average Inheritance';
    case 2
        evolutionPatternStr = 'Single-Parent Inheritance';
end


switch enableLearningRateEvolution
    case 0
        enableLearningRateEvolutionStr = 'Fixed Learning Rate';
    case 1
        enableLearningRateEvolutionStr = 'Evolving Learning Rat';
end

% Appearance ratio string
if appearanceRatioVal == 0
    appearanceRatioStr = 'No Appearance Feature';
else
    appearanceRatioStr = sprintf('$AR$=%.3f', appearanceRatioVal);
end

% LaTeX formatted label
s = sprintf(['$N$=%d, $M_{gen}$=%d, $R_{match}$=%d, $\\alpha$=%.2f, ', ...
    '$SR$=%.2f, $\\mu$=%.3f, $\\tau$=%.3f, %s, ', ...
    '%s, $\\beta$=%.1f, %s, %s'], ...
    numAgents, matchesPerGen, roundsPerMatch, learningRate, survivalRate, ...
    mutationRate, temperature, matchPatternStr, appearanceRatioStr, ...
    appearanceBonus, evolutionPatternStr, enableLearningRateEvolutionStr);
end



function vals = defaultSingleVals(name)
switch char(name)
    case 'numAgents'  % Number of agents
        vals = [5 10 20 40];
    case 'matchesPerGen'  % Matches per generation
        vals = [5 10 15 20];
    case 'roundsPerMatch' % Rounds per match
        vals = [5 10 15 20];
    case 'learningRate'   % Learning rate
        vals = [0.05 0.10 0.20 0.30];
    case 'survivalRate'   % Survival rate
        vals = [0.10 0.30 0.50 0.70 0.90];
    case 'mutationRate'   % Mutation rate (log scale)
        vals = logspace(-3, -1, 5);
    case 'temperature'    % Exploration temperature
        vals = [0.001 0.01 0.1 1];
    case 'matchPattern'   % Matching pattern
        vals = [0 1 4];  % Example: 0/1/2
    case 'appearanceRatio' % Enable appearance bonus
        vals = [0.1 0.3 0.5 0.7];  % Example: initial ratio
    case 'appearanceBonus' % Appearance bonus weight
        vals = [0 1 2 5];  % Example: bonus magnitude
    case 'evolutionPattern'      % Evolution pattern
        vals = [1 2];  % Example: pattern types
    case 'enableLearningRateEvolution' % Enable learning rate evolution
        vals = [0 1];  % ON/OFF
    otherwise
        error('Unknown parameter name "%s".', char(name));
end
end




function s = makeLabelSingle(idx, val)
    switch idx
        case 1
            s = sprintf('$N$=%d', val); % Number of agents
        case 2
            s = sprintf('$M_{gen}$=%d', val); % Matches per generation
        case 3
            s = sprintf('$R_{match}$=%d', val); % Rounds per match
        case 4
            s = sprintf('$\\alpha$=%.2f', val); % Learning Rate
        case 5
            s = sprintf('$SR$=%.2f', val); % Survival Rate
        case 6
            s = sprintf('$\\mu$=%.3f', val); % Mutation Rate
        case 7
            s = sprintf('$\\tau$=%.3f', val); % Temperature
        case 8
            % Matching pattern
            switch val
                case 0
                    s = 'Random';
                case 1
                    s = 'Optimistic-Max';
                case 2
                    s = 'Optimistic-Min';
                case 3
                    s = 'Pessimistic-Max';
                case 4
                    s = 'Pessimistic-Min';
                otherwise
                    s = sprintf('Pattern %d', val);
            end
        case 9
            s = sprintf('$AR$=%.3f', val); % Appearance Ratio
        case 10
            s = sprintf('$\\beta$=%.1f', val); % Appearance Bonus
        case 11
            % Evolution pattern
            switch val
                case 1
                    s = 'Average Inheritance';
                case 2
                    s = 'Single-Parent Inheritance';
                otherwise
                    s = sprintf('EP=%d', val);
            end
        case 12
            % Learning rate evolution flag
            if val == 0
                s = 'Fixed Learning Rate';
            else
                s = 'Evolving Learning Rate';
            end
        otherwise
            s = sprintf('Param%d=%.3f', idx, val);
    end
end
