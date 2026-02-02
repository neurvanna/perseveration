function mousedata = reconstructMousedataFromTrials(mouseName)
% Reconstruct mousedata_random from individual date folders and Trials files
%
% Inputs:
%   mouseName - e.g., 'AL063MOs'
%
% Output:
%   mousedata struct with fields:
%       choices
%       correct
%       laser_beep_all
%       laser_fb_all
%       beep_all_t
%       feedback_all_t
%       dates
%       nTrials

loadPath_opto;
baseDir = fullfile(mypath, 'random');
mouseDir = fullfile(baseDir, mouseName);

assert(exist(mouseDir,'dir')==7, 'Mouse folder not found');

%% List date folders
dateDirs = dir(mouseDir);
dateDirs = dateDirs([dateDirs.isdir]);
dateDirs = dateDirs(~ismember({dateDirs.name},{'.','..'}));

%% Initialize
choicesAll       = [];
correctAll       = [];
laserBeepAllAll  = [];
laserFbAllAll    = [];
beepAllT         = [];
feedbackAllT     = [];
datesAll         = {};

for d = 1:numel(dateDirs)

    datePath = fullfile(mouseDir, dateDirs(d).name);
    sessionDate = dateDirs(d).name;

    %% ---- Load Trials files ----
    % Choices
    cFile = fullfile(datePath,'Trials.choices.npy');
    assert(exist(cFile,'file'),'Missing Trials.choices.npy');
    choices = readNPY(cFile);
    choices = choices(:)'; % row vector

    % Correct
    corrFile = fullfile(datePath,'Trials.correctAnswers.npy');
    assert(exist(corrFile,'file'),'Missing Trials.correctAnswers.npy');
    correct = readNPY(corrFile);
    correct = correct(:)';

    % Laser at go cue
    laserGoFile = fullfile(datePath,'Trials.laserAtGoCue.npy');
    if exist(laserGoFile,'file')
        laserGo = readNPY(laserGoFile);
        laserGo = laserGo(:)';
    else
        laserGo = zeros(size(choices));
    end

    % Laser at feedback
    laserFbFile = fullfile(datePath,'Trials.laserAtFeedback.npy');
    if exist(laserFbFile,'file')
        laserFb = readNPY(laserFbFile);
        laserFb = laserFb(:)';
    else
        laserFb = zeros(size(choices));
    end

    % Go cue times
    goCueFile = fullfile(datePath,'Trials.goCueTimes.npy');
    if exist(goCueFile,'file')
        goCueTimes = readNPY(goCueFile);
        goCueTimes = goCueTimes(:)';
    else
        goCueTimes = NaN(size(choices));
    end

    % Feedback times
    fbFile = fullfile(datePath,'Trials.feedbackTimes.npy');
    if exist(fbFile,'file')
        fbTimes = readNPY(fbFile);
        fbTimes = fbTimes(:)';
    else
        fbTimes = NaN(size(choices));
    end

    %% Append to master
    nT = numel(choices);
    choicesAll       = [choicesAll, choices];
    correctAll       = [correctAll, correct];
    laserBeepAllAll  = [laserBeepAllAll, laserGo];
    laserFbAllAll    = [laserFbAllAll, laserFb];
    beepAllT         = [beepAllT, goCueTimes];
    feedbackAllT     = [feedbackAllT, fbTimes];
    datesAll         = [datesAll, repmat({sessionDate}, 1, nT)];
end

%% Assemble mousedata struct
nTrials = numel(choicesAll);

mousedata = struct();
mousedata.mousename        = mouseName;
mousedata.choices          = choicesAll;         % 1 x nTrials
mousedata.correct          = correctAll;         % 1 x nTrials
mousedata.laser_beep_all   = laserBeepAllAll;    % 1 x nTrials
mousedata.laser_fb_all     = laserFbAllAll;      % 1 x nTrials
mousedata.beep_all_t       = beepAllT;           % 1 x nTrials
mousedata.feedback_all_t   = feedbackAllT;       % 1 x nTrials
mousedata.dates            = datesAll;           % 1 x nTrials
mousedata.nTrials          = nTrials;            % scalar

%% Sanity check
assert( numel(mousedata.choices)          == nTrials && ...
        numel(mousedata.correct)          == nTrials && ...
        numel(mousedata.laser_beep_all)  == nTrials && ...
        numel(mousedata.laser_fb_all)    == nTrials && ...
        numel(mousedata.beep_all_t)      == nTrials && ...
        numel(mousedata.feedback_all_t)  == nTrials && ...
        numel(mousedata.dates)           == nTrials, ...
        'Reconstruction invariant violated');

end
