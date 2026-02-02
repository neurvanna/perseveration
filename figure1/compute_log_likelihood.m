function log_lik = compute_log_likelihood(agent, data, params)

% Set agent's parameters to the ones given
if exist('params', 'var')
    agent = agent.set_params(params);
end

% Reset the agent's state variables
agent = agent.new_sess;

% Run the agent through the dataset, track trial-by-trial log likelihood
log_lik = 0;
for trial_i = 1:data.nTrials
    if data.new_sess(trial_i)
        agent.new_sess;
    end
    if ~data.forced(trial_i)
        % get agent's choice probabilities
        choice_probs = agent.get_actionProbs;
        trial_likelihood = choice_probs(data.choices(trial_i));
        log_lik = log_lik + log(trial_likelihood);
    end
    
    % Create the trial struct that the agent's updater needs
    trial.new_sess = data.new_sess(trial_i);
    trial.choice = data.choices(trial_i);
    trial.reward = data.rewards(trial_i);
    
    % Update the agent
    agent = agent.update(trial);
        
end