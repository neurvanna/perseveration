function [fit_agent, params, log_lik] = fit_model(agent, data)

% How many fits must successfully complete?
min_n_successful = 3;

% Define the function to go into fmincon
funToFit = @(x) -1 * compute_log_likelihood(agent, data, x);

n_successful = 0;
while n_successful < min_n_successful
    try
        tic
        fprintf(['Fitting number ', num2str(n_successful + 1), ' of ', num2str(min_n_successful), '\n'])
        % Define the initial condition for this iteration of fmincon. Use parameter bounds specified in model
        lb4init = agent.lb; ub4init = agent.ub;
        % for any parameters that have a bound of inf (parameter is unbounded), init between -2 and 2
        lb4init(isinf(lb4init)) = -2; ub4init(isinf(ub4init)) = 2;
        % Pick a random init between those bounds
        init = rand(1,length(lb4init)).*(ub4init-lb4init)+lb4init;
        
        % Run fmincon!
        [fit_params, f_val] = fmincon(funToFit,init,[],[],[],[], agent.lb, agent.ub, [],...
            optimset('maxfunevals',4000,'maxiter',2000,'Display','notify-detailed','algorithm','interior-point'));
        
        % If it completed successfully, increment the success counter and
        % record the results
        n_successful = n_successful + 1;
        fit_params_all(n_successful,:) = fit_params;
        likelihoods_all(n_successful) = -1 * f_val;
        fprintf('Success! \n')
        
    catch err
        % If fmincon failed, print the error as a warning
        warning(['Error in fmincon:', err.message]);
    end
end


[log_lik, best_ind] = max(likelihoods_all);
params = fit_params_all(best_ind,:);
fit_agent = agent.set_params(params);

end
