function mousedata = reconstructMousedataFromTrialsNew(mouseName)
% Reconstruct mousedata from Trials.*.npy files
%
% baseDir   : path containing mouse folders
% mouseName : e.g. 'AL063MOs'
%
% Output:
%   mousedata with fields:
%       choices
%       correct
%       laser_fb_all
%       dates
%       nTrials

loadPath_opto;
baseDir = fullfile(mypath, '/halfSession/');
baseDir = fullfile(baseDir, mouseName);
assert(exist(baseDir,'dir')==7, 'Mouse folder not found');

%% Date folders
dateDirs = dir(baseDir);
dateDirs = dateDirs([dateDirs.isdir]);
dateDirs = dateDirs(~ismember({dateDirs.name},{'.','..'}));

%% Initialize
choicesAll    = [];
correctAll    = [];
laserFbAll    = [];
datesAll      = {};

for d = 1:numel(dateDirs)

    dateName = dateDirs(d).name;
    datePath = fullfile(baseDir, dateName);

    %% Required Trials files
    cFile  = fullfile(datePath,'Trials.choices.npy');
    caFile = fullfile(datePath,'Trials.correctAnswers.npy');

    if ~exist(cFile,'file') || ~exist(caFile,'file')
        continue
    end

    %% Load
    choices = readNPY(cFile);
    correct = readNPY(caFile);

    choices = choices(:)';   % force row
    correct = correct(:)';

    %% Optional laser
    lfFile = fullfile(datePath,'Trials.laserAtFeedback.npy');
    if exist(lfFile,'file')
        laserFb = readNPY(lfFile);
        laserFb = laserFb(:)';
    else
        laserFb = zeros(size(choices));
    end

    %% Consistency check
    nT = numel(choices);
    if numel(correct) ~= nT || numel(laserFb) ~= nT
        warning('Trial count mismatch in %s', datePath);
        continue
    end

    %% Append
    choicesAll = [choicesAll, choices];
    correctAll = [correctAll, correct];
    laserFbAll = [laserFbAll, laserFb];
    datesAll   = [datesAll, repmat({dateName}, 1, nT)];
end

%% Assemble mousedata
nTrials = numel(choicesAll);

mousedata = struct();
mousedata.choices        = choicesAll;    % 1 x nTrials
mousedata.correct        = correctAll;    % 1 x nTrials
mousedata.laser_fb_all   = laserFbAll;    % 1 x nTrials
mousedata.dates          = datesAll;      % 1 x nTrials cell
mousedata.nTrials        = nTrials;       % scalar

%% Final sanity check
assert( ...
    numel(mousedata.choices) == nTrials && ...
    numel(mousedata.correct) == nTrials && ...
    numel(mousedata.laser_fb_all) == nTrials && ...
    numel(mousedata.dates) == nTrials, ...
    'Reconstruction invariant violated');

end
