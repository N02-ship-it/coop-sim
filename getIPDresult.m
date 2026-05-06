function [Agent,rewardMatrix,CandCMatrix,matchCountMatrix]=getIPDresult(numAgents,numIPDRoundsPerMatch,Agent,R,numMatchPerGen,T,matchPattern,enableFixedStrategies)

rewardMatrix=zeros(numAgents);
CandCMatrix=zeros(numAgents);
matchCountMatrix=zeros(numAgents);
KAISU=0;

for K=1:numMatchPerGen
    ids = 1:numAgents;
    if matchPattern==0 %random
        matching_ids=ids(randperm(numAgents));

    elseif matchPattern==1 %Optimistic-Max
        QWAT_MAX=zeros(numAgents);
        for J=1:numAgents
            QWAT_MAX(J,:)=max(Agent(J).Q,[],2);
        end
        MatchingM=QWAT_MAX.*(QWAT_MAX');
        MatchingM=triu(MatchingM,1);
        matching_ids=zeros(numAgents,1);

        for J=1:2:numAgents-1
            temp=(MatchingM==max(max(MatchingM))).*rand(numAgents);
            [row,col] = find(temp==max(max(temp)));

            matching_ids(J)=row;
            matching_ids(J+1)=col;

            MatchingM(row,:)=0;
            MatchingM(col,:)=0;
            MatchingM(:,row)=0;
            MatchingM(:,col)=0;
        end

    elseif matchPattern==2%Optimistic-Min
        QWAT_MAX=zeros(numAgents);
        for J=1:numAgents
            QWAT_MAX(J,:)=max(Agent(J).Q,[],2);
        end
        MatchingM=QWAT_MAX.*(QWAT_MAX');
        MatchingM=triu(MatchingM,1);
        matching_ids=zeros(numAgents,1);
        MatchingM(MatchingM==0)=30;
        for J=1:2:numAgents-1
            temp=(MatchingM==min(min(MatchingM))).*rand(numAgents);
            [row,col] = find(temp==max(max(temp)));
            matching_ids(J)=row;
            matching_ids(J+1)=col;

            MatchingM(row,:)=30;
            MatchingM(col,:)=30;
            MatchingM(:,row)=30;
            MatchingM(:,col)=30;
        end

    elseif matchPattern==3 %Pessimistic-Max

        QWAT_MIN=zeros(numAgents);
        for J=1:numAgents
            QWAT_MIN(J,:)=min(Agent(J).Q,[],2);
        end
        MatchingM=QWAT_MIN.*(QWAT_MIN');
        MatchingM=triu(MatchingM,1);
        matching_ids=zeros(numAgents,1);

        for J=1:2:numAgents-1
            temp=(MatchingM==max(max(MatchingM))).*rand(numAgents);
            [row,col] = find(temp==max(max(temp)));

            matching_ids(J)=row;
            matching_ids(J+1)=col;

            MatchingM(row,:)=0;
            MatchingM(col,:)=0;
            MatchingM(:,row)=0;
            MatchingM(:,col)=0;
        end

    elseif matchPattern==4 %Pessimistic-Min

        QWAT_MIN=zeros(numAgents);
        for J=1:numAgents
            QWAT_MIN(J,:)=min(Agent(J).Q,[],2);
        end

        MatchingM=QWAT_MIN.*(QWAT_MIN');
        MatchingM=triu(MatchingM,1);
        matching_ids=zeros(numAgents,1);
        MatchingM(MatchingM==0)=30;

        for J=1:2:numAgents-1
            temp=(MatchingM==min(min(MatchingM))).*rand(numAgents);
            [row,col] = find(temp==max(max(temp)));

            matching_ids(J)=row;
            matching_ids(J+1)=col;

            MatchingM(row,:)=30;
            MatchingM(col,:)=30;
            MatchingM(:,row)=30;
            MatchingM(:,col)=30;
        end
    end

    for J=1:2:numAgents-1
        AA=matching_ids(J);
        BB=matching_ids(J+1);
        
AAfixStrategy = 0;
BBfixStrategy = 0;

        if AA==1
        AAfixStrategy=enableFixedStrategies;
        end
        if BB==1
        BBfixStrategy=enableFixedStrategies;
        end


        AATOTAL=0;
        BBTOTAL=0;
        CandC=0;
        AAhandhist=[];
        BBhandhist=[];

        for I=1:numIPDRoundsPerMatch
            KAISU=KAISU+1;
            [Agent,AATOTAL,BBTOTAL,CandC,AAhandhist,BBhandhist]=getTOTAL(Agent,AA,BB,CandC,AATOTAL,BBTOTAL,R,T,AAfixStrategy,BBfixStrategy,AAhandhist,BBhandhist);
        end
        matchCountMatrix(AA,BB)=matchCountMatrix(AA,BB)+numIPDRoundsPerMatch;
        matchCountMatrix(BB,AA)=matchCountMatrix(BB,AA)+numIPDRoundsPerMatch;
        rewardMatrix(AA,BB)=AATOTAL+rewardMatrix(AA,BB);
        rewardMatrix(BB,AA)=BBTOTAL+rewardMatrix(BB,AA);
        CandCMatrix(AA,BB)=CandC+CandCMatrix(AA,BB);
        CandCMatrix(BB,AA)=CandC+CandCMatrix(BB,AA);

    end
end
end

%%

function [Agent,AATOTAL,BBTOTAL,CandC,AAhandhist,BBhandhist]=getTOTAL(Agent,AA,BB,CandC,AATOTAL,BBTOTAL,R,T,AAfixStrategy,BBfixStrategy,AAhandhist,BBhandhist)


% ---- Previous round information (local, per match) ----

if numel(AAhandhist) >= 1 && numel(BBhandhist) >= 1
    AAlastHand   = AAhandhist(end);
    BBlastHand   = BBhandhist(end);
    AAlastReward = R(AAlastHand, BBlastHand);
    BBlastReward = R(BBlastHand, AAlastHand);
else
    AAlastHand   = [];
    BBlastHand   = [];
    AAlastReward = [];
    BBlastReward = [];
end


% ---- Decide hands ----
AAhand = decideHand(AA, BB, Agent, T, ...
                    AAfixStrategy, BBlastHand, AAlastHand, AAlastReward);

BBhand = decideHand(BB, AA, Agent, T, ...
                    BBfixStrategy, AAlastHand, BBlastHand, BBlastReward);

if AAhand==1 && BBhand==1
    CandC=CandC+1;
end

AATOTAL=AATOTAL+R(AAhand,BBhand);
BBTOTAL=BBTOTAL+R(BBhand,AAhand);


Agent(AA).Q(BB,AAhand)=Agent(AA).ALP*R(AAhand,BBhand)+(1-Agent(AA).ALP)*Agent(AA).Q(BB,AAhand);
Agent(BB).Q(AA,BBhand)=Agent(BB).ALP*R(BBhand,AAhand)+(1-Agent(BB).ALP)*Agent(BB).Q(AA,BBhand);

end

function hand = decideHand(agentID, opponentID, Agent, T, fixedStrategyMode, ...
                           oppLastHand, selfLastHand, selfLastReward)
% Decide action (hand) for a single agent
% hand = 1 : Cooperate
% hand = 2 : Defect
%
% fixedStrategyMode:
%   0 = RL (softmax)
%   1 = TFT
%   2 = WSLS (Pavlov)
%   3 = AllC
%   4 = AllD

switch fixedStrategyMode
    case 0  % RL
        hand = selecthandsm(Agent(agentID).Q(opponentID,:), T);

    case 1  % TFT
        if isempty(oppLastHand)
            hand = 1;   % cooperate first
        else
            hand = oppLastHand;
        end

    case 2  % WSLS (Pavlov)
        if isempty(selfLastReward) || isempty(selfLastHand)
            hand = 1;   % cooperate first
        else
            % Reward threshold:
            % CC (R=3) or DC (T=5) are "win" in standard PD
            if selfLastReward >= 3
                hand = selfLastHand;      % stay
            else
                hand = 3 - selfLastHand; % switch
            end
        end

    case 3  % AllC
        hand = 1;

    case 4  % AllD
        hand = 2;

    otherwise
        error('Unknown fixedStrategyMode = %d', fixedStrategyMode);
end
end





function out=selecthandsm(QA,T)

if (1/(1+exp((QA(2)-QA(1))/T)))>rand()
    out=1;
else
    out=2;
end
end