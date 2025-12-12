function NEWAgent=getNextGene(Mutation,rewardMatrix,Agent,Alpha,survivalRate,evolutionPattern,initialAppearanceRatio,AppBonus,enableAlphaEvolution)

NAgent=length(Agent);
ikinokori=randperm(NAgent);

for I=1:NAgent
    if I<=NAgent*survivalRate
        NEWAgent(I).ALP=Agent(ikinokori(I)).ALP;
        NEWAgent(I).DEFQ=Agent(ikinokori(I)).DEFQ;
        NEWAgent(I).APP=Agent(I).APP;
    else
        PICKUP=cumsum(sum(rewardMatrix,2)/(sum(rewardMatrix,"all")));
        tempP=rand();
        OYAA=sum(PICKUP<tempP)+1;

        OYAB=OYAA;
        while OYAA==OYAB
            PICKUP=cumsum(sum(rewardMatrix,2)/(sum(rewardMatrix,"all")));
            tempP=rand();
            OYAB=sum(PICKUP<tempP)+1;
        end

        if enableAlphaEvolution==1
            if rand()<Mutation
                NEWAgent(I).ALP=rand();
            elseif evolutionPattern==1
                NEWAgent(I).ALP=(Agent(OYAA).ALP+Agent(OYAB).ALP)/2;
            elseif evolutionPattern==2
                if rand()>0.5
                    NEWAgent(I).ALP=Agent(OYAA).ALP;
                else
                    NEWAgent(I).ALP=Agent(OYAB).ALP;
                end
            end
        else
            NEWAgent(I).ALP=Alpha;
        end

        if rand()<Mutation
            NEWAgent(I).DEFQ(1)=rand()*5;
        elseif evolutionPattern==1
            NEWAgent(I).DEFQ(1)=(Agent(OYAA).DEFQ(1)+Agent(OYAB).DEFQ(1))/2;
        elseif evolutionPattern==2
            if rand()>0.5
                NEWAgent(I).DEFQ(1)=Agent(OYAA).DEFQ(1);
            else
                NEWAgent(I).DEFQ(1)=Agent(OYAB).DEFQ(1);
            end
        end

        if rand()<Mutation
            NEWAgent(I).DEFQ(2)=rand()*5;
        elseif evolutionPattern==1
            NEWAgent(I).DEFQ(2)=(Agent(OYAA).DEFQ(2)+Agent(OYAB).DEFQ(2))/2;
        elseif evolutionPattern==2
            if rand()>0.5
                NEWAgent(I).DEFQ(2)=Agent(OYAA).DEFQ(2);
            else
                NEWAgent(I).DEFQ(2)=Agent(OYAB).DEFQ(2);
            end
        end

        if rand()<Mutation
            NEWAgent(I).APP=(rand()<initialAppearanceRatio);
        elseif rand()>0.5
            NEWAgent(I).APP=Agent(OYAA).APP;
        else
            NEWAgent(I).APP=Agent(OYAB).APP;
        end

    end
end


NApp=0;
for I=1:NAgent
    NEWAgent(I).Q=NEWAgent(I).DEFQ.*ones(NAgent,1);
    NApp=NApp+NEWAgent(I).APP;
    NEWAgent(I).Q(I,:)=[0,0];
end


if NApp > 0
    for I = 1:NAgent
        NBonus=NApp-NEWAgent(I).APP;
        if NBonus>0
            for J = 1:NAgent
                if NEWAgent(J).APP == 1 && ~(I==J)
                    NEWAgent(I).Q(J, 1) = NEWAgent(I).Q(J, 1) + AppBonus / NBonus;
                    NEWAgent(I).Q(J, 2) = NEWAgent(I).Q(J, 2) - AppBonus / NBonus;
                else
                    NEWAgent(I).Q(J, 1) = NEWAgent(I).Q(J, 1) - AppBonus / (NAgent-NBonus);
                    NEWAgent(I).Q(J, 2) = NEWAgent(I).Q(J, 2) + AppBonus / (NAgent-NBonus);
                end
            end
        end
        NEWAgent(I).Q(NEWAgent(I).Q > 5) = 5;
        NEWAgent(I).Q(NEWAgent(I).Q < 0) = 0;
    end
end