function mousedata = reconstructMouseData(mouseName)
% Reconstruct mousedata from standardized Trials.*.npy files
%
% Guarantees:
%   length(rewards) == length(choices) == length(dates) == length(forced)
%   all are 1 x nTrials

loadPath_ephys;
baseDir = fullfile(mypath, 'individual_dates_data');
mouseDir = fullfile(baseDir, mouseName);

assert(exist(mouseDir,'dir')==7, 'Mouse folder not found');

%% Experimental folders
expDirs = dir(mouseDir);
expDirs = expDirs([expDirs.isdir]);
expDirs = expDirs(~ismember({expDirs.name},{'.','..'}));

%% Initialize
choicesAll   = [];
rewardsAll   = [];
leftProbAll  = [];
rightProbAll = [];
datesAll     = {};
newSessAll   = [];

for e = 1:numel(expDirs)

    expPath = fullfile(mouseDir, expDirs(e).name);
    sessionDate = expDirs(e).name;

    %% Required files
    cFile  = fullfile(expPath,'Trials.choices.npy');
    rFile  = fullfile(expPath,'Trials.feedback.npy');
    caFile = fullfile(expPath,'Trials.correctAnswers.npy');

    if ~exist(cFile,'file') || ~exist(rFile,'file') || ~exist(caFile,'file')
        warning('Skipping %s (missing Trials files)', expPath);
        continue
    end

    %% Load
    choices = readNPY(cFile);
    rewards = readNPY(rFile);
    correct = readNPY(caFile);

    % Force row vectors
    choices = choices(:)';
    rewards = rewards(:)';
    correct = correct(:)';

    %% Consistency check within session
    nT = numel(choices);
    if numel(rewards) ~= nT || numel(correct) ~= nT
        warning('Skipping %s (trial count mismatch)', expPath);
        continue
    end

    %% Append
    choicesAll   = [choicesAll, choices];
    rewardsAll   = [rewardsAll, rewards];
    leftProbAll  = [leftProbAll, 0.5 - 0.3 * correct];
    rightProbAll = [rightProbAll, 0.5 + 0.3 * correct];
    datesAll     = [datesAll, repmat({sessionDate}, 1, nT)];

    % new_sess: 1 for first trial of this session, 0 otherwise
    newSessAll   = [newSessAll, 1, zeros(1, nT-1)];
end

%% Final assembly
nTrials = numel(choicesAll);

mousedata = struct();
mousedata.mousename   = mouseName;
mousedata.choices     = choicesAll/2 + 1.5;          % 1 x nTrials
mousedata.rewards     = rewardsAll;                  % 1 x nTrials
mousedata.left_prob1  = leftProbAll;                 % 1 x nTrials
mousedata.right_prob1 = rightProbAll;                % 1 x nTrials
mousedata.dates       = datesAll;                    % 1 x nTrials
mousedata.trial_types = repmat('f', 1, nTrials);     % 1 x nTrials
mousedata.new_sess    = newSessAll;                  % 1 x nTrials
mousedata.forced      = zeros(1, nTrials);           % 1 x nTrials
mousedata.nTrials     = nTrials;                      % scalar

%% Final sanity check (hard assert)
assert( ...
    numel(mousedata.choices)     == nTrials && ...
    numel(mousedata.rewards)     == nTrials && ...
    numel(mousedata.dates)       == nTrials && ...
    numel(mousedata.trial_types) == nTrials && ...
    numel(mousedata.new_sess)    == nTrials && ...
    numel(mousedata.forced)      == nTrials, ...
    'Reconstruction invariant violated');

end



