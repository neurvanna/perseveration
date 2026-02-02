%% Load data
% Data is saved in 200ms bins, from -1s to the event to +1s after the
% event, 10 timebins in total. 
% Therefore, timebin 5 in respAll_region_beep is the 200ms prior to the beep
% (fixation period), while timebins 6:10 in respAll_region_mov are the
% timebins right after the start of the movement

%% ============================
% Load data
%% ============================

respAll_goCue = extractBinnedSpikes('goCue', 'Secondary motor area');
respAll_movement = extractBinnedSpikes('mov', 'Secondary motor area');

behaviourAll = loadBehaviourVariable('choice');

%% PARAMETERS
minNeurons      = 30;
nBest           = 20;
numPermutations = 100;


%% -------------------------------------------------------
% Run analysis separately for goCue and movement
%% -------------------------------------------------------
[realLL_goCue, shuffLL_goCue] = ...
    run_analysis(respAll_goCue, behaviourAll, minNeurons, nBest, numPermutations);

[realLL_move, shuffLL_move] = ...
    run_analysis(respAll_movement, behaviourAll, minNeurons, nBest, numPermutations);

%% -------------------------------------------------------
% Plot: goCue (timebin 5) and movement (timebins 6–10)
%% -------------------------------------------------------
figure; hold on

% ---- goCue: timebin 5 ----
tb_gc = 5;
low_gc  = prctile(shuffLL_goCue(:,tb_gc),5);
high_gc = prctile(shuffLL_goCue(:,tb_gc),95);
mean_gc = mean(shuffLL_goCue(:,tb_gc));

fill([0.8 1.2 1.2 0.8], [low_gc low_gc high_gc high_gc], ...
     [0.8 0.8 0.8], 'EdgeColor','none', 'FaceAlpha',0.6)
%plot(1, mean_gc, 'o', 'Color',[0.5 0.5 0.5], 'MarkerFaceColor',[0.5 0.5 0.5])
plot(1, realLL_goCue(tb_gc), 'ko', 'MarkerFaceColor','k')

% ---- movement: timebins 6–10 ----
tbs_mv = 6:10;
x_mv   = 2:(1+numel(tbs_mv));

low_mv  = prctile(shuffLL_move(:,tbs_mv),5,1);
high_mv = prctile(shuffLL_move(:,tbs_mv),95,1);
mean_mv = mean(shuffLL_move(:,tbs_mv),1);

for i = 1:numel(tbs_mv)
    fill([x_mv(i)-0.2 x_mv(i)+0.2 x_mv(i)+0.2 x_mv(i)-0.2], ...
         [low_mv(i) low_mv(i) high_mv(i) high_mv(i)], ...
         [0.8 0.8 0.8], 'EdgeColor','none', 'FaceAlpha',0.6)
end

plot(x_mv, mean_mv, '-', 'Color',[0.5 0.5 0.5], 'LineWidth',1)
plot(x_mv, realLL_move(tbs_mv), 'ko', 'MarkerFaceColor','k')

%% formatting
xlim([0.5 max(x_mv)+0.5])
ylim([-0.9 -0.2])
xticks([1, 6.5])
xticklabels({'fixation period', 'movement+1s'})
xtickangle(45)
ylabel('Mean log_2 likelihood')
title('Decoding of real variable vs shuffle')
grid on






%% -------------------------------------------------------
% Helper function: run analysis for a given respAll
%% -------------------------------------------------------
function [realLL, shuffLL] = run_analysis(respAll, behaviourAll, minNeurons, nBest, numPermutations)

    % keep only sessions with at least minNeurons neurons
    nNeurons = cellfun(@(x) size(x,2), respAll);
    keepIdx  = nNeurons >= minNeurons;

    respAll      = respAll(keepIdx);
    behaviourAll = behaviourAll(keepIdx);

    nSessions = numel(respAll);

    % trim all sessions to minimal number of trials
    nTrials   = cellfun(@(x) size(x,1), respAll);
    minTrials = min(nTrials);
    for s = 1:nSessions
        respAll{s}      = respAll{s}(1:minTrials,:,:);
        behaviourAll{s} = behaviourAll{s}(1:minTrials);
    end

    nBins = size(respAll{1},3);

    %% REAL alignment
    realLL = nan(1,nBins);

    for tb = 1:nBins
        sessionLL = nan(nSessions,1);

        for s = 1:nSessions
            spikes    = squeeze(respAll{s}(:,:,tb));
            behaviour = behaviourAll{s}(:);

            % neuron ranking by squared correlation
            r2s = nan(size(spikes,2),1);
            for n = 1:size(spikes,2)
                r2s(n) = corr(spikes(:,n), behaviour).^2;
            end

            [~, best_neurons] = maxk(r2s, nBest);

            mdl   = fitglm(spikes(:,best_neurons), behaviour, ...
                           'Distribution','binomial');
            ypred = predict(mdl, spikes(:,best_neurons));

            ll = 0;
            for ii = 1:length(behaviour)
                if behaviour(ii)==1
                    ll = ll + log2(ypred(ii));
                else
                    ll = ll + log2(1-ypred(ii));
                end
            end
            sessionLL(s) = ll / length(behaviour);
        end

        realLL(tb) = mean(sessionLL);
    end

    %% SHUFFLED: full permutations, reused across all time bins
    shuffLL = nan(numPermutations, nBins);

    for p = 1:numPermutations

        sessionOrder = randperm(nSessions);

        behaviourPerm = cell(1,nSessions);
        for s = 1:nSessions
            behaviourPerm{s} = behaviourAll{sessionOrder(s)};
        end

        for tb = 1:nBins
            sessionLL = nan(nSessions,1);

            for s = 1:nSessions
                spikes    = squeeze(respAll{s}(:,:,tb));
                behaviour = behaviourPerm{s}(:);

                r2s = nan(size(spikes,2),1);
                for n = 1:size(spikes,2)
                    r2s(n) = corr(spikes(:,n), behaviour).^2;
                end

                [~, best_neurons] = maxk(r2s, nBest);

                mdl   = fitglm(spikes(:,best_neurons), behaviour, ...
                               'Distribution','binomial');
                ypred = predict(mdl, spikes(:,best_neurons));

                ll = 0;
                for ii = 1:length(behaviour)
                    if behaviour(ii)==1
                        ll = ll + log2(ypred(ii));
                    else
                        ll = ll + log2(1-ypred(ii));
                    end
                end
                sessionLL(s) = ll / length(behaviour);
            end

            shuffLL(p,tb) = mean(sessionLL);
        end
    end
end

