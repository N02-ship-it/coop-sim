clear variables
clc

% ===== 実行時間計測の準備 =====
startTime = datetime('now','Format','yyyyMMdd_HHmmss');
tic;

% rng(1);
baseSeed=0;

R=[3 0;5 1];
numTrials=1000;
numGenerations=50;

ResultDirectoryName=['results_' char(datetime('now','Format','yyyy-MM-dd_HH-mm-ss'))];

checkParamNames = {'numAgents','matchesPerGen','roundsPerMatch','learningRate','survivalRate','mutationRate','temperature','matchPattern','appearanceRatio','appearanceBonus','evolutionPattern','enableLearningRateEvolution','enableFixedStrategies','Rm_Mg','mu_alpha','apps'};
% checkParamNames = {'appearanceRatio' 'appearanceBonus' 'apps'};
% checkParamNames = {'learningRate'};
% checkParamNames = {'Rm_Mg'};
% checkParamNames = {'Rm_Mg','mu_alpha','apps'};
% checkParamNames = {'numAgents'};
% checkParamNames = {'enableFixedStrategies'};

for II = 1:length(checkParamNames)

    paramName = checkParamNames{II};
    [paramList, paramStrings, labelStrings, axisInfo, patternType] = createParamList(paramName);

    rewardResults=zeros(size(paramList,1),numGenerations,numTrials);
    cooperationRateResults=zeros(size(paramList,1),numGenerations,numTrials);

    coopRateMeanByGen=zeros(numGenerations,size(paramList,1));
    coopRateStdByGen=zeros(numGenerations,size(paramList,1));
    finalCoopRatePerTrial=zeros(size(paramList,1),numTrials);

    disp(paramList)
    disp(labelStrings)

    

    for PP=1:size(paramList,1)

        numAgents=paramList(PP,1);
        numMatchPerGen=paramList(PP,2);
        numIPDRoundsPerMatch=paramList(PP,3);
        learningRate=paramList(PP,4);
        survivalRate=paramList(PP,5);
        mutationRate=paramList(PP,6);
        temperature=paramList(PP,7);
        matchPattern=paramList(PP,8);
        appearanceRatio=paramList(PP,9);
        appearanceBonus=paramList(PP,10);
        evolutionPattern=paramList(PP,11);
        enableLearningRateEvolution=paramList(PP,12);
        enableFixedStrategies=paramList(PP,13);

        disp(paramStrings{PP})
        for TT=1:numTrials
        runID = (PP-1)*numTrials + TT;
        rng(baseSeed + runID)

            Agent=setFirstAgent(numAgents,learningRate,appearanceRatio,appearanceBonus,enableLearningRateEvolution);

            for GG=1:numGenerations
                [Agent,rewardMatrix,CandCMatrix,matchCountMatrix]=getIPDresult(numAgents,numIPDRoundsPerMatch,Agent,R,numMatchPerGen,temperature,matchPattern,enableFixedStrategies);
                rewardResults(PP,GG,TT)=sum(rewardMatrix,'all');
                cooperationRateResults(PP,GG,TT)=sum(CandCMatrix,'all')/sum(matchCountMatrix,'all');

                Agent=getNextGene(mutationRate,rewardMatrix,Agent,learningRate,survivalRate,evolutionPattern,appearanceRatio,appearanceBonus,enableLearningRateEvolution,enableFixedStrategies);

            end
            finalCoopRatePerTrial(PP,TT)=cooperationRateResults(PP,GG,TT);
        end

        meanCoopRatePerGen=mean(cooperationRateResults(PP,:,:),3);
        stdCoopRatePerGen=std(cooperationRateResults(PP,:,:),0,3);
        coopRateMeanByGen(:,PP)=meanCoopRatePerGen(:);
        coopRateStdByGen(:,PP)=stdCoopRatePerGen(:);

        finalCoopRateMeanAllParams=mean(cooperationRateResults(:,numGenerations,:),3);
        finalCoopRateVarAllParams=var(cooperationRateResults(:,numGenerations,:),1);
    end

    mkdir(ResultDirectoryName)
    switch patternType
        case {'numAgents','matchesPerGen','roundsPerMatch','learningRate','survivalRate','mutationRate','temperature','matchPattern','appearanceRatio','appearanceBonus','evolutionPattern','enableLearningRateEvolution','enableFixedStrategies'}
            saveSimulationResults(ResultDirectoryName, patternType, paramStrings, labelStrings, paramList, coopRateMeanByGen, coopRateStdByGen, finalCoopRatePerTrial, numGenerations)
        case {'Rm_Mg' 'mu_alpha' 'apps'}
            saveHeatmapResults(ResultDirectoryName, axisInfo, patternType, paramStrings, paramList, cooperationRateResults, numGenerations)
    end

end

% ===== 実行時間の取得 =====
elapsedTime = toc;

% ===== 保存先フォルダ（この .m ファイルと同じ） =====
thisFilePath = mfilename('fullpath');
[thisFolder, ~, ~] = fileparts(thisFilePath);

% ===== ファイル名（開始時刻ベース） =====
logFileName = sprintf('runtime_%s.txt', startTime);
logFilePath = fullfile(thisFolder, logFileName);

% ===== テキストファイルに書き込み =====
fid = fopen(logFilePath, 'w');
fprintf(fid, 'Program start time : %s\n', startTime);
fprintf(fid, 'Elapsed time (sec) : %.6f\n', elapsedTime);
fclose(fid);