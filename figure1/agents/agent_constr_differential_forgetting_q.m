classdef agent_constr_differential_forgetting_q
    
    properties
        % Parameters
        alpha_learn
        alpha_forget
        kappa_learn_plus
        kappa_learn_minus
        bias
        % Agent State Variables
        Q
    end
    
    properties (Constant)
        stan_file = 'agent_differential_forgetting';
        % Parameter Bounds
        lb = [0, 0.9999, -inf, -inf, -inf];
        ub = [1, 1, inf, inf, inf];
    end
    
    methods
        
        %% Constructor
        function self = agent_differential_forgetting_q(params)
            %if ~exist('params', 'var')
            if ~isempty('params')
                params = zeros(1, length(self.lb));
            end
            % Assign parameters
            self = self.set_params(params);
            % Initialize a new session
            self = self.new_sess;
        end
        
        %% Define generic "parameters" in terms of named internal variables
        function params = get_params(self)
            params = [self.alpha_learn,      self.alpha_forget, ...
                self.kappa_learn_plus, self.kappa_learn_minus, self.bias];
        end
        
        function self = set_params(self, params)
            n_params = length(self.lb);
            assert(length(params) == n_params, ...
                ['This agent requires exactly ', num2str(n_params), ' parameters'])
            assert(isnumeric(params), 'Params must all be numeric')
            
            % Check params are within bounds
            assert(all(params >= self.lb) && all(params <= self.ub),...
                'One or more of the parameters specified is out of bounds');
            
            % Copy parameters as named properties
            self.alpha_learn = params(1);
            self.alpha_forget = params(2);
            self.kappa_learn_plus = params(3);
            self.kappa_learn_minus = params(4);
            self.bias = params(5);
            
        end
        
        %% Define generic "agent state" in terms of named internal variables
        % For this agent, it is just Q
        function agent_state = get_agent_state(self)
            agent_state = self.Q;
        end
        
        function self = set_agent_state(self, agent_state)
            self.Q = agent_state;
        end
        
        %% Define action probs
        function actionProbs = get_actionProbs(self)
            Qeff = [self.Q(1) + self.bias, self.Q(2) - self.bias];
            actionProbs = exp(Qeff) / sum(exp(Qeff));
        end
        
        %% New Session
        function self = new_sess(self)
            self.Q = [0.5, 0.5];
        end
        
        %% Make choice
        function choice = make_choice(self)
            actionProbs = self.get_actionProbs;
            choice = (rand < actionProbs(1));
            choice = double(choice==0) + 1; % Choice as 1 or 2
        end
        
        %% Update
        function self = update(self, trial)
            
            % If this is the beginning of a new session, reset beliefs
            if trial.new_sess
                self = self.new_sess;
            end
            
            % Decide which learning target to use for the chosen side
            % For this agent, target on the unchosen side is always zero
            if trial.reward
                kappa = self.kappa_learn_plus;
            elseif ~trial.reward
                kappa = self.kappa_learn_minus;
            end
            
            % Get indices of the chosen and unchosen side
            chosen = trial.choice;
            unchosen = (trial.choice==1) + 1;
            
            % Update Q
            new_Q = [NaN, NaN];
            new_Q(chosen) =   (1-self.alpha_learn)   * self.Q(chosen) + self.alpha_learn * kappa;
            new_Q(unchosen) = (1-self.alpha_forget) * self.Q(unchosen);
            
            self.Q = new_Q;
        end
        
    end
end