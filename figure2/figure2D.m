
clear all

feedbackTimes = loadBehaviourVariable('feedbackTimes');
goCueTimes = loadBehaviourVariable('goCueTimes');
for i =1:length(goCueTimes)
    rt{i} = feedbackTimes{i} - goCueTimes{i};
end
P = loadBehaviourVariable('P');


plot_rt_vs_P_quantiles(P, rt)




function plot_rt_vs_P_quantiles(P, rt)

    nBins = 8;

    % Concatenate P across all sessions
    P_all = horzcat(P{:});

    % Define global quantile edges
    edges = quantile(P_all, linspace(0, 1, nBins+1));
    edges(1)   = -inf;
    edges(end) = inf;

    nSessions = numel(P);
    rt_bin_session = nan(nSessions, nBins);

    % Loop over sessions
    for s = 1:nSessions
        P_s  = P{s}(:);
        rt_s = rt{s}(:);

        % Skip if empty
        if isempty(rt_s)
            continue
        end

        % Center RTs: subtract mean of this session
        rt_s_centered = rt_s - mean(rt_s, 'omitnan');

        % Assign trials to bins
        binIdx = discretize(P_s, edges);

        % Mean centered RT per bin (per session)
        for b = 1:nBins
            idx = binIdx == b;
            if any(idx)
                rt_bin_session(s, b) = mean(rt_s_centered(idx), 'omitnan');
            end
        end
    end

    % Mean across sessions
    rt_mean = mean(rt_bin_session, 1, 'omitnan');

    % SEM across sessions (standard deviation / sqrt(n))
    rt_sem = std(rt_bin_session, 0, 1, 'omitnan') ./ sqrt(sum(~isnan(rt_bin_session), 1));

    % Plot
    figure; hold on
    errorbar(1:nBins, rt_mean, rt_sem, 'o-', ...
        'LineWidth', 2, 'MarkerSize', 6)

    xlabel('P quantile (low → high)')
    ylabel('RT minus session mean (mean ± SEM)')
    xlim([0.5 nBins+0.5])
    yline(0, '--k') % optional reference line at 0

    box off
    set(gca, 'FontSize', 12)

end

