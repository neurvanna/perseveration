classdef agent_habits_only
    
    properties
        % Parameters
        alpha_habit
        beta_habit
        beta_bias
        % Agent state variables
        H
    end
    
    properties (Constant)
        stan_file = 'agent_habits_only';
        % Parameter Bounds
        lb = [0, -inf, -inf];
        ub = [1, inf, inf];
    end
    
    methods
        
        %% Constructor
        function self = agent_habits_only(params)
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
            params = [self.alpha_habit, ...
                      self.beta_habit, self.beta_bias];
        end
        
        function self = set_params(self, params)
            n_params = length(self.lb);
            if isempty(params)
                params = zeros(1, n_params);
            end
            assert(length(params) == n_params, ...
                ['This agent requires exactly ', num2str(n_params), ' parameters'])
            assert(isnumeric(params), 'Params must all be numeric')
            
            % Check params are within bounds
            assert(all(params >= self.lb) && all(params <= self.ub),...
                'One or more of the parameters specified is out of bounds');
            
            % Copy params as named properties
            self.alpha_habit = params(1);
            self.beta_habit = params(2);
            self.beta_bias = params(3);
        end
        
        %% Define "agent state" in terms of named internal variables
        
        function agent_state = get_agent_state(self)
            agent_state = self.H;
        end
        
        function self = set_agent_state(self, agent_state)
            self.H = agent_state(1);
        end
        
        %% Define action probs
        function actionProbs = get_actionProbs(self)
            Veff = self.beta_habit * self.H + self.beta_bias;
            actionProbs = [logistic(-1*Veff), logistic(Veff)];
        end
        
        %% New Session
        function self = new_sess(self)
            self.H = 0;
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
            
            choice_for_learning = 2 * (trial.choice - 1.5); % Choice as -1 left, +1 right
            
            self.H = (1 - self.alpha_habit) * self.H + self.alpha_habit * choice_for_learning;
            
        end
        
    end
    
end