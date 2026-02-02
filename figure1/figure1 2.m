loadPath_ephys;
baseDir = fullfile(mypath, 'individual_dates_data');

d = dir(baseDir);
d = d([d.isdir]);
d = d(~ismember({d.name},{'.','..'}));

mouseNames = {d.name};   % 1 x number of mice


%% Model comparison using cross-validated likelihood
models = {
    agent_vanilla_q, ...
    agent_optimistic_q, ...
    agent_differential_forgetting_q,...
    agent_actor_critic,...
    agent_bayes_flips,...
    agent_bayes_drifts,...
    agent_local_matching,...
    agent_rs_habits,...
    agent_foraging, ...
    agent_bayes_anna, ...
    agent_bayes_habits_anna, ...
    agent_bayes_drifts_habits, ...
    agent_bayes_flips_habits, ...
    };

lbls = {
    'vanilla q', ...
    'optimistic q', ...
    'differential forgetting q',...
    'actor critic',...
    'bayes flips',...
    'bayes drifts',...
    'local matching',...
    'RL with perseveration',...
    'foraging',...
    'ideal observer', ...
    'ideal observer with perseveration',...
    'drifts with perseveration', ...
    'flips with perseveration' ...
    };
    
% Check if cross-validated likelihood exists already; regenerate if not.

if ~isfile('xval_results.mat')
    for mouseInd = 1:length(mouseNames)
        mousedata = reconstructMouseData(mouseNames{mouseInd});
        for model_i = 1:length(models)
    
            agent = models{model_i};
    
            fit_agents{model_i} = fit_model(agent, mousedata);
    
            xval_results(model_i, mouseInd) = cross_validate_even_odd(agent, mousedata);
            %[xval_results.norm_lik_xval]
        end
    end
    
    save('xval_results', 'xval_results', 'model_names')
end

%%

load('xval_results')
mouseNames = xval_results.mouseNames;
xval_results = xval_results.data;
xval_results = xval_results([2:end], :);
figure; hold on;
clear this_model_mean
for mouseInd = 1:length(mouseNames)
    for model_i = 1:size(xval_results, 1)
        this_model_likelihood(model_i,mouseInd) = (xval_results(model_i,mouseInd).norm_lik_xval);
    end 
end 
this_model_mean = mean(this_model_likelihood,2);



[~, inds] = sort(this_model_mean);


likelihood_sorted = [];
for mouse = 1:length(mouseNames)
    likelihood_sorted(:, mouse) = this_model_likelihood(inds, mouse);
end
  
hold on;

for mouse = 1:length(mouseNames)
    plot(likelihood_sorted(:, mouse), '.k')
    plot(likelihood_sorted(:, mouse), 'k')
end






xticks(1:size(xval_results, 1))
xticklabels(lbls(inds));
xtickangle(45) 
xlim([0, length(lbls)+1]) 
 ylabel('likelihood')
makepretty()


