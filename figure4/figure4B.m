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

behaviourAll = loadBehaviourVariable('choice');



%% ============================
% Parameters
%% ============================
leave_only_sessions_with_N_neurons = 60;
subsampleSizes  = 10:10:60;
num_permutations = 100;
timeBin = 5;

%% ============================
% Preallocate outputs
%% ============================
answer_real     = cell(length(subsampleSizes),1);
answer_shuffled = cell(length(subsampleSizes),1);

%% ============================
% Main loop over subsample sizes
%% ============================
subsampleSizeIdx = 0;
for subsampleSize = subsampleSizes
    subsampleSizeIdx = subsampleSizeIdx + 1;

    %% 1) Keep only sessions with >= 60 neurons
    keepIdx = cellfun(@(x) size(x,2) >= leave_only_sessions_with_N_neurons, respAll_goCue);
    resp  = respAll_goCue(keepIdx);
    behav = behaviourAll(keepIdx);

    nSessions = length(resp);

    %% 2) Trim to minimal number of trials
    nTrials   = cellfun(@(x) size(x,1), resp);
    minTrials = min(nTrials);

    for s = 1:nSessions
        resp{s}  = resp{s}(1:minTrials,:,:);
        behav{s} = behav{s}(1:minTrials);
    end

    %% 3) Random neuron subsampling (ONCE per subsample size)
    for s = 1:nSessions
        idx = randperm(size(resp{s},2), subsampleSize);
        resp{s} = resp{s}(:, idx, :);
    end

    %% 4) REAL session order
    sessionOrder = 1:nSessions;
    answer_real{subsampleSizeIdx} = ...
        compute_bin_loglik(resp, behav, sessionOrder, timeBin);

    %% 5) SHUFFLED session order (complete permutations)
    tmp = zeros(num_permutations,1);
    for p = 1:num_permutations
        sessionOrder = randperm(nSessions);
        tmp(p) = compute_bin_loglik(resp, behav, sessionOrder, timeBin);
    end
    answer_shuffled{subsampleSizeIdx} = tmp;
end

%% ============================
% Plotting 
%% ============================
nSub = length(subsampleSizes);
nPerm = num_permutations;

aRe  = zeros(1,nSub);
aShu = zeros(nSub,nPerm);

for i = 1:nSub
    aRe(i)      = answer_real{i};
    aShu(i,:)   = answer_shuffled{i}';
end

% Real − shuffled per permutation
diffRS = aRe - mean(aShu, 2)';


figure; plot(diffRS)

xlim([0.5 nSub+0.5])
xticks(1:nSub)
xticklabels(subsampleSizes)
xlabel('number of neurons in the sample')
ylabel('predictability relative to shuffle')
title('MOs: subsampled random neurons, bin 5 (200 ms before go cue)')
ylim([-0.02 0.13])
box off

%% ============================
% Function: single-bin log-likelihood
%% ============================
function meanLL = compute_bin_loglik(resp, behav, sessionOrder, timeBin)

nSessions = length(resp);
sessLL = zeros(1,nSessions);

% Permute behavior across sessions
behavPerm = cell(1,nSessions);
for s = 1:nSessions
    behavPerm{s} = behav{sessionOrder(s)};
end

for s = 1:nSessions
    spikes    = squeeze(resp{s}(:,:,timeBin));
    behaviour = behavPerm{s}(:);

    assert(all(ismember(behaviour,[0 1])))

    mdl   = fitglm(spikes, behaviour, 'Distribution','binomial');
    ypred = predict(mdl, spikes);

    ll = 0;
    for ii = 1:length(behaviour)
        if behaviour(ii)==1
            ll = ll + log2(ypred(ii));
        else
            ll = ll + log2(1 - ypred(ii));
        end
    end

    sessLL(s) = ll / length(behaviour);
end

meanLL = mean(sessLL);
end
