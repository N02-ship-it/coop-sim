function Agent=setFirstAgent(NAgent,Alpha,initialAppearanceRatio,AppBonus,enableAlphaEvolution)

NApp=floor(NAgent*initialAppearanceRatio);
for I=1:NAgent
    if enableAlphaEvolution==1
        Agent(I).ALP=rand();
    else
        Agent(I).ALP=Alpha;
    end

    Agent(I).DEFQ=[rand()*5,rand()*5];
    Agent(I).Q=Agent(I).DEFQ.*ones(NAgent,1);
    Agent(I).Q(I,:)=[0,0];
    Agent(I).APP=(I<=NApp);
end

if NApp > 0
    for I = 1:NAgent
        NBonus=NApp-Agent(I).APP;
        NMbonus=NAgent-NApp-(Agent(I).APP==0);
        if NBonus>0
            for J = 1:NAgent
                if Agent(J).APP == 1 && ~(I==J)
                    Agent(I).Q(J, 1) = Agent(I).Q(J, 1) + AppBonus / NBonus;
                    Agent(I).Q(J, 2) = Agent(I).Q(J, 2) - AppBonus / NBonus;
                else
                    Agent(I).Q(J, 1) = Agent(I).Q(J, 1) - AppBonus / NMbonus;
                    Agent(I).Q(J, 2) = Agent(I).Q(J, 2) + AppBonus / NMbonus;
                end
            end
        end
        Agent(I).Q(Agent(I).Q > 5) = 5;
        Agent(I).Q(Agent(I).Q < 0) = 0;
    end
end