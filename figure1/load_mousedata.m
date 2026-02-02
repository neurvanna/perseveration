% This function loads data. Fitting code requires specific data format, for
% example it requires a field "forced", that it set to 0 here because no
% choices are forced. Also, the new_sess field is 1 when the previous date is
% not the same as the next, indicating that this trial is the first trial of a new session.
% Choice is transformed to be either 1 or 2 for plot_learning_curve.

function data = load_mousedata(filename)

loaded = load(filename);
mousedata = loaded.mousedata;

prev_date = '';
data = struct();

for trial_i = 1:mousedata.nTrials
    data.rewards(trial_i) = mousedata.rewards(trial_i);
    data.choices(trial_i) = 1 + (mousedata.sides(trial_i)=='l');

    % If this trial's sessiondate doesn't match the previous trial's, it's
    % the first trial in a new session
    if strcmp(prev_date, mousedata.dates{trial_i})
        data.new_sess(trial_i) = 0;
    else
        data.new_sess(trial_i) = 1;
        prev_date = mousedata.dates{trial_i};
    end
    
    % In Anna's mouse data, there are never forced choice trials
    data.forced(trial_i) = 0;
    
    data.leftProbs(trial_i) = mousedata.left_prob1(trial_i);
    data.rightProbs(trial_i) = mousedata.right_prob1(trial_i);
    
end



data.nTrials = mousedata.nTrials;
data.name = mousedata.mousename;

end

