function [respAll, mouseNames] = extractBinnedSpikes(timebin, brainRegion)
% Extract binned spikes for all sessions
%
% Inputs:
%   timebin - 'goCue', 'fb', or 'mov'
%   brainRegion - string specifying brain area of interest, or 'any'
%
% Outputs:
%   respAll - 1 x number of sessions cell array, each cell: trials x neurons x 10
%   mouseNames (optional) - 1 x number of sessions cell array with mouse names

if nargout > 1
    mouseNames = {};
end

%% Input validation
validBins = {'goCue','fb','mov'};
assert(ismember(timebin, validBins), 'Invalid timebin');

loadPath_ephys;
rootDir = mypath;

%% Time bins
edges = -1.0:0.2:1.0;
nBins = numel(edges) - 1;

respAll = {};
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

        respAll{idxSession} = [];

        if nargout > 1
            mouseNames{idxSession} = animalDirs(a).name;
        end

        %% Required spike files
        spikeTimesFile = fullfile(expPath,'spikes.times.npy');
        spikeClustersFile = fullfile(expPath,'spikes.clusters.npy');
        if ~exist(spikeTimesFile,'file') || ~exist(spikeClustersFile,'file')
            continue
        end

        %% Load spikes
        st = readNPY(spikeTimesFile);
        st = double(st)./30000;  % convert to seconds
        sc = readNPY(spikeClustersFile);

        %% Load alignment times
        switch timebin
            case 'goCue'
                S = load(fullfile(expPath,'Trials.goCueTimes.mat'));
                alignTimes = S.goCueTimes;
            case 'fb'
                S = load(fullfile(expPath,'Trials.feedbackTimes.mat'));
                alignTimes = S.feedbackTimes;
            case 'mov'
                S = load(fullfile(expPath,'Trials.movementTimes.mat'));
                alignTimes = S.movementTimes;
        end

        alignTimes = alignTimes(:);
        nTrials = numel(alignTimes);

        %% Determine which clusters to keep
        clustersWithSpikes = unique(sc);
        clustersWithSpikes = sort(clustersWithSpikes);
        nClusters = numel(clustersWithSpikes);

        if ~strcmp(brainRegion,'any')
            % ---- LOAD unit_area FROM TEXT FILE ----
            txtFile = fullfile(expPath,'Clusters.brainLocation_ccf_2017.txt');
            if ~exist(txtFile, 'file')
                warning('Missing brain region file: %s', txtFile);
                continue
            end

            unit_area = readlines(txtFile);
            unit_area = cellstr(unit_area);

            if numel(unit_area) < nClusters
                warning('%s: unit_area shorter than clusters with spikes', expPath);
                continue
            end

            % Select clusters in the region
            isInRegion = strcmp(unit_area(1:nClusters), brainRegion);
            keepClusters = clustersWithSpikes(isInRegion);
        else
            % Keep all clusters
            keepClusters = clustersWithSpikes;
        end

        if isempty(keepClusters)
            continue
        end

        %% Allocate output
        nNeurons = numel(keepClusters);
        spikeCounts = zeros(nTrials, nNeurons, nBins);

        %% Bin spikes
        for n = 1:nNeurons
            cid = keepClusters(n);
            spikeTimesNeuron = st(sc == cid);

            for t = 1:nTrials
                relTimes = spikeTimesNeuron - alignTimes(t);
                spikeCounts(t,n,:) = histcounts(relTimes, edges);
            end
        end

        respAll{idxSession} = spikeCounts;
    end
end
end
