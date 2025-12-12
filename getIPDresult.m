function [Agent,rewardMatrix,CandCMatrix,matchCountMatrix]=getIPDresult(numAgents,numIPDRoundsPerMatch,Agent,R,numMatchPerGen,T,matchPattern)

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

        AATOTAL=0;
        BBTOTAL=0;
        CandC=0;

        for I=1:numIPDRoundsPerMatch
            KAISU=KAISU+1;
            [Agent,AATOTAL,BBTOTAL,CandC]=getTOTAL(Agent,AA,BB,CandC,AATOTAL,BBTOTAL,R,T);
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

function [Agent,AATOTAL,BBTOTAL,CandC]=getTOTAL(Agent,AA,BB,CandC,AATOTAL,BBTOTAL,R,T)

AAhand=selecthandsm(Agent(AA).Q(BB,:),T);
BBhand=selecthandsm(Agent(BB).Q(AA,:),T);
if AAhand==1 && BBhand==1
    CandC=CandC+1;
end

AATOTAL=AATOTAL+R(AAhand,BBhand);
BBTOTAL=BBTOTAL+R(BBhand,AAhand);
Agent(AA).Q(BB,AAhand)=Agent(AA).ALP*R(AAhand,BBhand)+(1-Agent(AA).ALP)*Agent(AA).Q(BB,AAhand);
Agent(BB).Q(AA,BBhand)=Agent(BB).ALP*R(BBhand,AAhand)+(1-Agent(BB).ALP)*Agent(BB).Q(AA,BBhand);

end

function out=selecthandsm(QA,T)

if (1/(1+exp((QA(2)-QA(1))/T)))>rand()
    out=1;
else
    out=2;
end
end