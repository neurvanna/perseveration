function results = cross_validate_even_odd(agent, data)
% Computes a cross-validated log likelihood score for the agent, using the dataset in data.
% Divides the dataset into even and odd sessions. Fits a set of agent parameters to each. 
% Computes likelihood using each set of parameters on the held-out dataset. Reports both training-set and held-out likelihood scores.

% Create seperate datasets containing even-numbered and odd-numbered sessions
sessions = divide_into_sessions(data);
even_sessions = sessions(1:2:end);
odd_sessions = sessions(2:2:end);
data_even = merge_datas(even_sessions);
data_odd = merge_datas(odd_sessions);

% Fit an agent to each
agent_even = fit_model(agent, data_even);
agent_odd = fit_model(agent, data_odd);

% Evaluate each agent on each dataset
log_lik_fit = compute_log_likelihood(agent_even, data_even) + ...
    compute_log_likelihood(agent_odd, data_odd);
log_lik_xval = compute_log_likelihood(agent_even, data_odd) + ...
    compute_log_likelihood(agent_odd, data_even);

% Compute normalized likelihoods
n_free_trials = sum(~data.forced);
results.norm_lik_fit = exp(log_lik_fit / n_free_trials);
results.norm_lik_xval = exp(log_lik_xval / n_free_trials);

% Package results
results.log_lik_fit = log_lik_fit;
results.log_lik_xval = log_lik_xval;

results.agent_even = agent_even;
results.agent_odd = agent_odd;

end
