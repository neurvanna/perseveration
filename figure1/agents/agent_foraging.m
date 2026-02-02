classdef agent_foraging
    
    properties
        % Parameters
        alpha_local
        beta
        bias_stay
        bias_left
        V_init
        % Agent State Variables
        V_local
        previous_choice
    end
    
    properties (Constant)
        stan_file = '';
        % Parameter Bounds
        lb = [0, -inf, -inf, -inf, 0];
        ub = [1, inf, inf, inf, inf];
    end
    
    methods
        
        %% Constructor
        function self = agent_foraging(params)
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
            params = [self.alpha_local, self.beta, self.bias_stay, self.bias_left, self.V_init];
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
            self.alpha_local = params(1);
            self.beta = params(2);
            self.bias_stay = params(3);
            self.bias_left = params(4);
            self.V_init = params(5);
        end
        
        %% Define generic "agent state" in terms of named internal variables
        % For this agent, it is just Q
        function agent_state = get_agent_state(self)
            agent_state = [self.V_local, self.previous_choice];
        end
        
        function self = set_agent_state(self, agent_state)
            self.V_local = agent_state(1);
            self.previous_choice = agent_state(2);
        end
        
        %% Define action probabilities
        function actionProbs = get_actionProbs(self)
            stay_switch_logit = self.beta * self.V_local + self.bias_stay;
            
            if self.previous_choice == 1
                left_right_logit = -1*stay_switch_logit + self.bias_left;
            else
                left_right_logit = stay_switch_logit + self.bias_left;
            end
            actionProbs(1) = 1 / (1 + exp(left_right_logit));
            actionProbs(2) = 1 - actionProbs(1);
        end
        
        %% New Session
        function self = new_sess(self)
            self.previous_choice = rand < 0.5;
            self.V_local = self.V_init;
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
            
            if trial.choice == self.previous_choice
                self.V_local = (1 - self.alpha_local) * self.V_local + self.alpha_local * trial.reward;
            else
                self.previous_choice = trial.choice;
                self.V_local = self.V_init;
            end
            
        end
        
    end
end