function behaviourAll = loadBehaviourVariable(varName)
% Load a behavioural variable from all experimental folders
%
% Input:
%   varName - string, one of: 'choice', 'P', 'feedback'
% Output:
%   behaviourAll - 1 x total number of sessions, each cell 1 x nTrials

validVars = {'choice','P','feedback', 'feedbackTimes', 'movementTimes', 'goCueTimes'};
assert(ismember(varName, validVars), 'Invalid variable name');

loadPath_ephys;
rootDir = mypath;

behaviourAll = {};

idxSession = 0;

%% Animal folders
animalDirs = dir(rootDir);
animalDirs = animalDirs([animalDirs.isdir]);
animalDirs = animalDirs(~ismember({animalDirs.name},{'.','..'}));

for a = 1:numel(animalDirs)
    animalPath = fullfile(rootDir, animalDirs(a).name);

    expDirs = dir(animalPath);
    expDirs = expDirs([expDirs.isdir]);
    expDirs = expDirs(~ismember({expDirs.name},{'.','..'}));

    for e = 1:numel(expDirs)
        expPath = fullfile(animalPath, expDirs(e).name);
        idxSession = idxSession + 1;

        behaviourAll{idxSession} = [];  % default empty

        % Determine file name
        switch varName
            case 'choice'
                matFile = fullfile(expPath,'Trials.choices.mat');
            case 'P'
                matFile = fullfile(expPath,'Trials.P.mat');
            case 'feedback'
                matFile = fullfile(expPath,'Trials.feedback.mat');
            case 'feedbackTimes'
                matFile = fullfile(expPath,'Trials.feedbackTimes.mat');
            case 'movementTimes'
                matFile = fullfile(expPath,'Trials.movementTimes.mat');
            case 'goCueTimes'
                matFile = fullfile(expPath,'Trials.goCueTimes.mat');
        end

        if ~exist(matFile, 'file')
            warning('File missing: %s', matFile);
            continue
        end

        % Load the variable
        S = load(matFile);

        if ~isfield(S, varName)
            % Sometimes variable inside mat has a different name than file
            fields = fieldnames(S);
            if numel(fields) == 1
                varData = S.(fields{1});
            else
                warning('Unexpected variables in %s', matFile);
                continue
            end
        else
            varData = S.(varName);
        end

        % Ensure 1 x nTrials
        varData = reshape(varData, 1, []);

        % ---- NEW: convert choice from 1/-1 → 1/0 ----
        if strcmp(varName, 'choice')
            varData(varData == -1) = 0;
        end

        behaviourAll{idxSession} = varData;
    end
end

end

