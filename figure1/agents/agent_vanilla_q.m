classdef agent_vanilla_q
    
    properties
        % Parameters
        alpha
        beta
        bias
        % Agent State Variables
        Q
    end
    
    properties (Constant)
        stan_file = 'agent_vanilla_q';
        % Parameter Bounds
        lb = [0, -inf, -inf];
        ub = [1, inf, inf];
    end
    
    methods
        
        %% Constructor
        function self = agent_vanilla_q(params)
            if ~exist('params', 'var')
                params = zeros(1, length(self.lb));
            end
            % Assign parameters
            self = self.set_params(params);
            % Initialize a new session
            self = self.new_sess;
        end
        
        %% Define generic "parameters" in terms of named internal variables
        function params = get_params(self)
            params = [self.alpha, self.beta, self.bias];
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
            self.alpha = params(1);
            self.beta = params(2);
            self.bias = params(3);
        end
        
        %% Define generic "agent state" in terms of named internal variables
        % For this agent, it is just Q
        function agent_state = get_agent_state(self)
            agent_state = self.Q;
        end
        
        function self = set_agent_state(self, agent_state)
            self.Q = agent_state;
        end
        
        %% Define action probabilities
        function actionProbs = get_actionProbs(self)
            Qeff = [self.beta*self.Q(1) + self.bias, self.beta*self.Q(2) - self.bias];
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
        
        %% Update Rule
        function self = update(self, trial)
            
            % If this is the beginning of a new session, reset beliefs
            if trial.new_sess
                self = self.new_sess;
            end
            
            % Get indices of the chosen and unchosen side
            chosen = trial.choice;
            unchosen = (trial.choice==1) + 1;
            
            % Update Q
            new_Q(chosen) =   (1-self.alpha)   * self.Q(chosen) + self.alpha * trial.reward;
            new_Q(unchosen) = self.Q(unchosen);
            
            self.Q = new_Q;
        end
        
    end
end