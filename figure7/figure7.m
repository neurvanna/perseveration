%% Parameters
before_switch = 10;
whichLength   = 50;
region        = 'MOs';
nFake         = 100;


if strcmp(region, 'MOs')
    miceAll = {'AL063MOs', 'AL064MOs', 'AL065MOs', 'AL081MOs', 'AL083MOs', 'AL084MOs'}; % MOs mice
elseif strcmp(region, 'mPFC')
    miceAll = {'AL070mPFC', 'AL071mPFC', 'AL072mPFC', 'AL076mPFC', 'AL077mPFC', 'AL082mPFC', 'AL087mPFC'}; % mPFC mice
end

x = -before_switch:whichLength;

%% Containers (real)
perfLaserAll   = [];
perfNoLaserAll = [];

%% Containers (fake)
perfLaserFake   = cell(nFake,1);
perfNoLaserFake = cell(nFake,1);

%% =========================
%        MAIN LOOP
% =========================
for iMouse = 1:length(miceAll)
    mouse = miceAll{iMouse};
    mousedata = reconstructMousedataFromTrialsNew(mouse);
    
    correctAll = mousedata.correct;
    laserAll   = mousedata.laser_fb_all;
    datesAll   = mousedata.dates;
    responsesAll = mousedata.choices*2-1;
    
    uniqueDates = unique(datesAll);
    
    %% Loop over sessions
    for iDate = 1:length(uniqueDates)
        idxSess = find(strcmp(datesAll,uniqueDates{iDate}));
        
        correct   = correctAll(idxSess);
        responses = responsesAll(idxSess);
        laser     = laserAll(idxSess);
        nTrials   = length(correct);
        
        % Block flips
        blockSwitches = 1 + find(abs(diff(correct)) > 1);
        blockSwitches = blockSwitches(blockSwitches > before_switch & ...
                                      blockSwitches + whichLength <= nTrials);
        if isempty(blockSwitches), continue; end
        
        % Laser switch
        switchTrial = find(diff(laser) ~= 0,1);
        if isempty(switchTrial)
            switchTrial = nTrials;
        end
        
        %% =========================
        %        REAL DATA
        % =========================
        laserInTheBeginning = laser(1) > 0;
        
        if laserInTheBeginning
            blocksLaser   = blockSwitches(blockSwitches < switchTrial - whichLength);
            blocksNoLaser = blockSwitches(blockSwitches > switchTrial + before_switch);
        else
            blocksLaser   = blockSwitches(blockSwitches > switchTrial + before_switch);
            blocksNoLaser = blockSwitches(blockSwitches < switchTrial - whichLength);
        end
        
        if ~isempty(blocksLaser)
        for idx = blocksLaser'
            perfLaserAll(end+1,:) = ...
                responses(idx-before_switch:idx+whichLength) == ...
                correct(idx-before_switch:idx+whichLength);
        end
        end
        if ~isempty(blocksNoLaser)
        for idx = blocksNoLaser'
            perfNoLaserAll(end+1,:) = ...
                responses(idx-before_switch:idx+whichLength) == ...
                correct(idx-before_switch:idx+whichLength);
        end
        end
        
        %% =========================
        %        FAKE LASER
        % =========================
        for f = 1:nFake
            fakeLaserInBeginning = rand < 0.5;
            
            if fakeLaserInBeginning
                blocksLaserF   = blockSwitches(blockSwitches < switchTrial - whichLength);
                blocksNoLaserF = blockSwitches(blockSwitches > switchTrial + before_switch);
            else
                blocksLaserF   = blockSwitches(blockSwitches > switchTrial + before_switch);
                blocksNoLaserF = blockSwitches(blockSwitches < switchTrial - whichLength);
            end
            
            if ~isempty(blocksLaserF)
            for idx = blocksLaserF'
                perfLaserFake{f}(end+1,:) = ...
                    responses(idx-before_switch:idx+whichLength) == ...
                    correct(idx-before_switch:idx+whichLength);
            end
            end
            
            if ~isempty(blocksNoLaserF)
            for idx = blocksNoLaserF'
                perfNoLaserFake{f}(end+1,:) = ...
                    responses(idx-before_switch:idx+whichLength) == ...
                    correct(idx-before_switch:idx+whichLength);
            end
            end
        end
    end
end

%% =========================
%        PLOT 1: ACCURACY
% =========================
figure; hold on;

meanNo = mean(perfNoLaserAll,1);
semNo  = std(perfNoLaserAll,[],1)/sqrt(size(perfNoLaserAll,1));

meanLa = mean(perfLaserAll,1);
semLa  = std(perfLaserAll,[],1)/sqrt(size(perfLaserAll,1));

fill([x fliplr(x)], [meanNo+semNo fliplr(meanNo-semNo)], ...
     'b','FaceAlpha',0.3,'EdgeColor','none');
plot(x,meanNo,'b','LineWidth',2)

fill([x fliplr(x)], [meanLa+semLa fliplr(meanLa-semLa)], ...
     'r','FaceAlpha',0.3,'EdgeColor','none');
plot(x,meanLa,'r','LineWidth',2)

xlabel('Trials from block flip')
ylabel('Accuracy')
legend({'No laser','Laser'})
ylim([0 1])
title('Block-aligned accuracy')
grid on

%% =========================
%   PLOT 2: DIFFERENCES
% =========================
figure; hold on;

realDiff = meanLa - meanNo;

fakeDiff = nan(nFake,length(x));
for f = 1:nFake
    fakeDiff(f,:) = mean(perfLaserFake{f},1) - mean(perfNoLaserFake{f},1);
    plot(x,fakeDiff(f,:),'Color',[0.8 0.8 0.8],'LineWidth',0.5)
end

plot(x,realDiff,'Color',[1 0.4 0.6],'LineWidth',3)

% Significance: real < 1th percentile of fake
fakeThresh = prctile(fakeDiff,1,1);
sigIdx = realDiff < fakeThresh;

plot(x(sigIdx), 0.27,'r*','MarkerSize',8)

xlabel('Trials from block flip')
ylabel('Laser – No laser accuracy')
title('Real vs fake laser difference')
grid on
