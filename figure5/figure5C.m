


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Projection-based regression analysis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear; close all;

%% ---------------- PARAMETERS ----------------
numPerm = 100;
nBest   = 20;
timeBin = 5;

%% ============================
% Load data
%% ============================

% Neural data

respAll_goCue = extractBinnedSpikes('goCue', 'Secondary motor area');

% Behavioral data
P = loadBehaviourVariable('P');
C = loadBehaviourVariable('choice');

nSessions = numel(P);

behaviourAll = cell(1,nSessions);
for i = 1:nSessions
    behaviourAll{i}.P      = P{i};
    behaviourAll{i}.choice = C{i};
end

%% ---------------- BUILD processedData -------
processedData = {};
sessIdx = 0;

for s = 1:length(respAll_goCue)
    if size(respAll_goCue{s},2) >= 30
        sessIdx = sessIdx + 1;
        processedData{sessIdx}.spikes = respAll_goCue{s};
        processedData{sessIdx}.choice = behaviourAll{s}.choice(:)';
        processedData{sessIdx}.Pvar   = behaviourAll{s}.P(:)';
    end
end

nSess = length(processedData);
assert(nSess > 1);

%% ---------------- TRIM TRIALS ----------------
nTrials = zeros(1,nSess);
for s = 1:nSess
    nTrials(s) = length(processedData{s}.choice);
end
minTrials = min(nTrials);

for s = 1:nSess
    processedData{s}.choice = processedData{s}.choice(1:minTrials);
    processedData{s}.Pvar   = processedData{s}.Pvar(1:minTrials);
    processedData{s}.spikes = processedData{s}.spikes(1:minTrials,:,:);
end

%% ---------------- BUILD GLOBAL PROJECTION ----
projectionMatrix = zeros(nSess, minTrials);
predictionMatrix = zeros(nSess, minTrials);

for s = 1:nSess
    projectionMatrix(s,:) = processedData{s}.choice;
    predictionMatrix(s,:) = processedData{s}.Pvar;
end

[U,~,~] = svd(projectionMatrix', 'econ');
I = eye(size(U,1));
Pproj = I - U*U';

%% ---------------- REAL DATA ------------------
sessionOrder = 1:nSess;
answer_real = run_projection_match(processedData, predictionMatrix, ...
                                   sessionOrder, Pproj, nBest, timeBin);

%% ---------------- SHUFFLED DATA --------------
answer_shuffled = zeros(numPerm,1);
for p = 1:numPerm
    sessionOrder = randperm(nSess);  % COMPLETE permutation
    answer_shuffled(p) = run_projection_match(processedData, predictionMatrix, ...
                                              sessionOrder, Pproj, nBest, timeBin);
end

%% ---------------- PLOT -----------------------
figure; hold on;
histogram(answer_shuffled, 20, 'FaceColor', [.7 .7 .7], 'EdgeColor', 'none');
yl = ylim;
plot([answer_real answer_real], yl, 'k-', 'LineWidth', 3);
xlabel('Mean squared error');
ylabel('Count');
title('Projection regression (fixation period)');
box off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ---------------- HELPER FUNCTION  ---
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function mse_mean = run_projection_match(processedData, predictionMatrix, ...
                                         sessionOrder, Pproj, nBest, timeBin)

nSess = length(processedData);
session_mses = zeros(nSess,1);

for s = 1:nSess
    spikes = squeeze(processedData{s}.spikes(:,:,timeBin));

    % Pull P-variable from shuffled session
    behaviour = predictionMatrix(sessionOrder(s), :)';

    % Project behavior only
    behaviour_proj = Pproj * behaviour;

    % Neuron selection using projected behavior
    r2 = zeros(size(spikes,2),1);
    for n = 1:size(spikes,2)
        r = corr(spikes(:,n), behaviour_proj);
        r2(n) = r^2;
    end
    [~, bestIdx] = maxk(r2, nBest);

    % Linear regression (NO projection of spikes)
    mdl = fitlm(spikes(:,bestIdx), behaviour_proj);
    session_mses(s) = mdl.MSE;
end

mse_mean = mean(session_mses);

end
