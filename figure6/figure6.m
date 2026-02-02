%% Mouse list
region = 'MOs';

loadPath_opto;
baseDir = fullfile(mypath, '/random/');
mouseDirs = dir(baseDir);
mouseDirs = mouseDirs([mouseDirs.isdir]);
mouseDirs = mouseDirs(~ismember({mouseDirs.name},{'.','..'}));

switch region
    case 'MOs'
        miceAll = {mouseDirs(contains({mouseDirs.name}, 'MOs')).name};

    case 'mPFC'
        miceAll = {mouseDirs(contains({mouseDirs.name}, 'mPFC')).name};

    otherwise
        error('Unknown region: %s', region);
end
nMice = numel(miceAll);

%% Preallocate
acc_beep0 = nan(nMice,1);
acc_beep1 = nan(nMice,1);
rep_beep0 = nan(nMice,1);
rep_beep1 = nan(nMice,1);

acc_fb0 = nan(nMice,1);
acc_fb1 = nan(nMice,1);
rep_fb0 = nan(nMice,1);
rep_fb1 = nan(nMice,1);

%% Loop over mice
for iM = 1:nMice

    mouse = miceAll{iM};

    mousedata = reconstructMousedataFromTrials(mouse);


    laser_beep = mousedata.laser_beep_all(:);
    laser_fb   = mousedata.laser_fb_all(:);
    choice     = mousedata.choices(:);
    correctAns = mousedata.correct(:);

    % ---- Define correct trials ----
    correct = (choice == correctAns);

    %% ===============================
    % Accuracy: laser_beep
    %% ===============================
    acc_beep0(iM) = mean(correct(laser_beep == 0), 'omitnan');
    acc_beep1(iM) = mean(correct(laser_beep == 1), 'omitnan');

    %% ===============================
    % Repeat probability: laser_beep
    %% ===============================
    repeat = choice(2:end) == choice(1:end-1);
    beep_prev = laser_beep(1:end-1);

    rep_beep0(iM) = mean(repeat(beep_prev == 0), 'omitnan');
    rep_beep1(iM) = mean(repeat(beep_prev == 1), 'omitnan');

    %% ===============================
    % Accuracy: following laser_fb
    %% ===============================
    fb_prev = laser_fb(1:end-1);
    correct_curr = correct(2:end);

    acc_fb0(iM) = mean(correct_curr(fb_prev == 0), 'omitnan');
    acc_fb1(iM) = mean(correct_curr(fb_prev == 1), 'omitnan');

    %% ===============================
    % Repeat probability: following laser_fb
    %% ===============================
    rep_fb0(iM) = mean(repeat(fb_prev == 0), 'omitnan');
    rep_fb1(iM) = mean(repeat(fb_prev == 1), 'omitnan');
end

%% SEM helper
sem = @(x) nanstd(x) ./ sqrt(sum(~isnan(x)));

%% ===============================
%           PLOTTING
%% ===============================

figure('Color','w','Position',[200 200 900 600])

%% ---- Accuracy: laser_beep ----
subplot(2,2,1)
bar([1 2],[mean(acc_beep0) mean(acc_beep1)]); hold on
errorbar([1 2],[mean(acc_beep0) mean(acc_beep1)], ...
         [sem(acc_beep0) sem(acc_beep1)], '.k', 'LineWidth', 1.5)

[~,p] = ttest(acc_beep0, acc_beep1);
if p < 0.05
    text(1.5, 0.8, '*', 'Color','r', ...
        'FontSize',22,'HorizontalAlignment','center')
end

set(gca,'XTick',[1 2],'XTickLabel',{'Beep OFF','Beep ON'})
ylabel('Accuracy')
title('Accuracy by laser\_beep')
ylim([0.55 0.85])

%% ---- Repeat: laser_beep ----
subplot(2,2,3)
bar([1 2],[mean(rep_beep0) mean(rep_beep1)]); hold on
errorbar([1 2],[mean(rep_beep0) mean(rep_beep1)], ...
         [sem(rep_beep0) sem(rep_beep1)], '.k', 'LineWidth', 1.5)

[~,p] = ttest(rep_beep0, rep_beep1);
if p < 0.05
    text(1.5, 0.95, '*', 'Color','r', ...
        'FontSize',22,'HorizontalAlignment','center')
end

set(gca,'XTick',[1 2],'XTickLabel',{'Beep OFF','Beep ON'})
ylabel('P(repeat)')
title('Repeat probability by laser\_beep')
ylim([0.6 1])

%% ---- Accuracy: following laser_fb ----
subplot(2,2,2)
bar([1 2],[mean(acc_fb0) mean(acc_fb1)]); hold on
errorbar([1 2],[mean(acc_fb0) mean(acc_fb1)], ...
         [sem(acc_fb0) sem(acc_fb1)], '.k', 'LineWidth', 1.5)

[~,p] = ttest(acc_fb0, acc_fb1);
if p < 0.05
    text(1.5, 0.8, '*', 'Color','r', ...
        'FontSize',22,'HorizontalAlignment','center')
end

set(gca,'XTick',[1 2],'XTickLabel',{'FB OFF','FB ON'})
ylabel('Accuracy')
title('Accuracy following laser\_fb')
ylim([0.55 0.85])

%% ---- Repeat: following laser_fb ----
subplot(2,2,4)
bar([1 2],[mean(rep_fb0) mean(rep_fb1)]); hold on
errorbar([1 2],[mean(rep_fb0) mean(rep_fb1)], ...
         [sem(rep_fb0) sem(rep_fb1)], '.k', 'LineWidth', 1.5)

[~,p] = ttest(rep_fb0, rep_fb1);
if p < 0.05
    text(1.5, 0.95, '*', 'Color','r', ...
        'FontSize',22,'HorizontalAlignment','center')
end

set(gca,'XTick',[1 2],'XTickLabel',{'FB OFF','FB ON'})
ylabel('P(repeat)')
title('Repeat probability following laser\_fb')
ylim([0.6 1])




%% ===============================
%           Reaction Time Analysis
%% ===============================

rt_mean0 = nan(nMice,1);
rt_mean1 = nan(nMice,1);

figure('Color','w','Position',[300 300 600 400])
hold on

edges = 0:0.01:1; % 10 ms bins
cdf_all0 = nan(nMice, length(edges));
cdf_all1 = nan(nMice, length(edges));

for iM = 1:nMice
    mouse = miceAll{iM};

    mousedata = reconstructMousedataFromTrials(mouse);


    laser_beep = mousedata.laser_beep_all(:);
    beep_t     = mousedata.beep_all_t(:);
    fb_t       = mousedata.feedback_all_t(:);

    % Reaction time
    rt = fb_t - beep_t;
    

    % Per-mouse mean RT
    rt_mean0(iM) = mean(rt(laser_beep == 0), 'omitnan');
    rt_mean1(iM) = mean(rt(laser_beep == 1), 'omitnan');

    % CDF per mouse
    for j = 1:length(edges)
        cdf_all0(iM,j) = mean(rt(laser_beep == 0) <= edges(j), 'omitnan');
        cdf_all1(iM,j) = mean(rt(laser_beep == 1) <= edges(j), 'omitnan');
    end
end

% Average CDF across mice
cdf0 = mean(cdf_all0,1);
cdf1 = mean(cdf_all1,1);

% Plot CDFs
plot(edges, cdf0, 'b', 'LineWidth',2);
plot(edges, cdf1, 'r', 'LineWidth',2);
xlabel('Reaction Time (s)')
ylabel('Cumulative Probability')
legend('Beep OFF','Beep ON','Location','southeast')
title('Cumulative probability of reaction time')
xlim([0 1])
ylim([0 1])
grid on

%% ---- Signrank test for mean RT across mice ----
p = signrank(rt_mean0, rt_mean1);
y_star = 0.95; % star position

if p < 0.05
    text(0.5, y_star, '*', 'Color','r', 'FontSize',22, ...
        'HorizontalAlignment','center')
end

fprintf('Mean RT Signrank test: p = %.4f\n', p);
