clear all

choice = loadBehaviourVariable('choice');
feedbackTimes = loadBehaviourVariable('feedbackTimes');
goCueTimes = loadBehaviourVariable('goCueTimes');
for i =1:length(goCueTimes)
    rt{i} = feedbackTimes{i} - goCueTimes{i};
end
[~, mouseNames] = extractBinnedSpikes('goCue', 'any'); % just need to know which mouse each session came from


plot_rt_by_mouse_repetition(rt, choice, mouseNames)


function plot_rt_by_mouse_repetition(rt, choice, mouseNames)

    % Time axis
    t = linspace(0, 4, 400);

    % Unique mice
    mice = unique(mouseNames);
    nMice = numel(mice);

    % Store per-mouse CDFs
    cdf_rep_all    = nan(nMice, numel(t));
    cdf_nonrep_all = nan(nMice, numel(t));

    figure; hold on

    for m = 1:nMice
        % Sessions for this mouse
        idx = strcmp(mouseNames, mice{m});

        rt_rep_mouse    = [];
        rt_nonrep_mouse = [];

        % Loop over sessions
        sessIdx = find(idx);
        for s = sessIdx
            rt_s     = rt{s}(:);
            choice_s = choice{s}(:);

            if numel(rt_s) < 2
                continue
            end

            % Repeated choice definition
            repeated = choice_s(2:end) == choice_s(1:end-1);
            rt_valid = rt_s(2:end);

            rt_rep_mouse    = [rt_rep_mouse;    rt_valid(repeated)];
            rt_nonrep_mouse = [rt_nonrep_mouse; rt_valid(~repeated)];
        end

        % Total counts (including RT > 4 s)
        n_rep_total    = numel(rt_rep_mouse);
        n_nonrep_total = numel(rt_nonrep_mouse);

        % Empirical cumulative probability (NOT renormalized)
        cdf_rep = arrayfun(@(x) sum(rt_rep_mouse <= x)    / n_rep_total,    t);
        cdf_nonrep = arrayfun(@(x) sum(rt_nonrep_mouse <= x) / n_nonrep_total, t);

        cdf_rep_all(m, :)    = cdf_rep;
        cdf_nonrep_all(m, :) = cdf_nonrep;

        % Plot individual mice (light)
        plot(t, cdf_rep,    'Color', [1 0.6 0.6], 'LineWidth', 1)
        plot(t, cdf_nonrep, 'Color', [0.6 0.6 1], 'LineWidth', 1)
    end

    % Mean across mice
    mean_rep    = mean(cdf_rep_all, 1, 'omitnan');
    mean_nonrep = mean(cdf_nonrep_all, 1, 'omitnan');

    % Plot means (bold)
    plot(t, mean_rep,    'r', 'LineWidth', 3)
    plot(t, mean_nonrep, 'b', 'LineWidth', 3)

    xlabel('Reaction time (s)')
    ylabel('Cumulative probability')
    xlim([0 4])
    ylim([0 1])

    legend({'Repeated (mouse)', 'Non-repeated (mouse)', ...
            'Repeated (mean)', 'Non-repeated (mean)'}, ...
            'Location', 'southeast')

    title('Reaction time cumulative probability (not renormalized)')
    box off
    set(gca, 'FontSize', 12)

end
