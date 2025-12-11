clear variables
clc
rng(1);

R=[3 0;5 1];
numTrials=1000;
numGenerations=50;

ResultDirectoryName=['results_' char(datetime('now','Format','yyyy-MM-dd_HH-mm-ss'))];

% checkParamNames = {'numAgents','matchesPerGen','roundsPerMatch','learningRate','survivalRate','mutationRate','temperature','matchPattern','appearanceRatio','appearanceBonus','evolutionPattern','enableLearningRateEvolution','Rm_Mg','mu_alpha','apps'};
% chaeckParamNames = {'appearanceRatio' 'appearanceBonus' 'apps'};
% checkParamNames = {'learningRate'};
% checkParamNames = {'apps'};

checkParamNames = {'matchPattern'};

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

        disp(paramStrings{PP})
        for TT=1:numTrials

            Agent=setFirstAgent(numAgents,learningRate,appearanceRatio,appearanceBonus,enableLearningRateEvolution);
            for GG=1:numGenerations
                [Agent,rewardMatrix,CandCMatrix,matchCountMatrix]=getIPDresult(numAgents,numIPDRoundsPerMatch,Agent,R,numMatchPerGen,temperature,matchPattern);
                rewardResults(PP,GG,TT)=sum(rewardMatrix,'all');
                cooperationRateResults(PP,GG,TT)=sum(CandCMatrix,'all')/sum(matchCountMatrix,'all');

                Agent=getNextGene(mutationRate,rewardMatrix,Agent,learningRate,survivalRate,evolutionPattern,appearanceRatio,appearanceBonus,enableLearningRateEvolution);

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
        case {'numAgents','matchesPerGen','roundsPerMatch','learningRate','survivalRate','mutationRate','temperature','matchPattern','appearanceRatio','appearanceBonus','evolutionPattern','enableLearningRateEvolution'}
            saveSimulationResults(ResultDirectoryName, patternType, paramStrings, labelStrings, paramList, coopRateMeanByGen, coopRateStdByGen, finalCoopRatePerTrial, numGenerations)
        case {'Rm_Mg' 'mu_alpha' 'apps'}
            saveHeatmapResults(ResultDirectoryName, axisInfo, patternType, paramStrings, paramList, cooperationRateResults, numGenerations)
    end

end