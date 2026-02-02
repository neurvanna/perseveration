classdef agent_actor_critic
    
    properties
        % Parameters
        alpha_actor_learn
        alpha_actor_forget
        alpha_critic
        % State Variables
        V
        H
    end
    
    properties (Constant)
        stan_file = '';
        % Parameter Bounds
        lb = [0, 0, 0];
        ub = [1, 1, 1];
    end
    
    methods
        
        %% Constructor
        function self = agent_actor_critic(params)
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
           params = [self.alpha_actor_learn, self.alpha_actor_forget, self.alpha_critic]; 
        end
        
        function self = set_params(self, params)
            % Check there are the right number of parameters, and that
            % they are all numeric
            n_params = length(self.lb);
            assert(length(params) == n_params, ...
                ['This agent requires exactly ', num2str(n_params), ' parameters'])
            assert(isnumeric(params), 'Params must all be numeric')
            % Check params are within bounds
            assert(all(params >= self.lb) && all(params <= self.ub),...
                'One or more of the parameters specified is out of bounds');
            
            % Copy parameters as named properties
            self.alpha_actor_learn = params(1);
            self.alpha_actor_forget = params(2);
            self.alpha_critic = params(3);
        end
        
        
        %% Define generic "agent state" in terms of named internal variables
        function agent_state = get_agent_state(self)
            agent_state = [self.V, self.H];
        end
        
        function self = set_agent_state(self, agent_state)
            self.V = agent_state(1);
            self.H = agent_state(2);
        end
        
        %% New Session
        function self = new_sess(self)
            self.V = 0.5;
            self.H = [0,0];
        end
        
        %% Make choice
        function actionProbs = get_actionProbs(self)
            if abs(self.H(1)) > 500 % If H is huge, make this deterministic, to avoid numerical issues
                actionProbs = [self.H(1) > self.H(2), self.H(2) > self.H(1)];
            else % Otherwise, choose using a softmax
                actionProbs = exp(self.H) / sum(exp(self.H));
            end
        end
        
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
            
            chosen = trial.choice;
            unchosen = (trial.choice==1) + 1;
            
            % Actor learning: Update H
            new_H = [NaN, NaN];
            actionProbs = self.get_actionProbs;
            new_H(chosen)   = (1 - self.alpha_actor_forget) * self.H(chosen)   + ...
                self.alpha_actor_learn * (trial.reward - self.V) * (1 - actionProbs(chosen));
            
            new_H(unchosen) = (1 - self.alpha_actor_forget) * self.H(unchosen) - ...
                self.alpha_actor_learn * (trial.reward - self.V) * (actionProbs(unchosen));
            
            self.H = new_H;
            
            % Critic learning: Update V
            new_V = (1 - self.alpha_critic) * self.V + self.alpha_critic * trial.reward;
            self.V = new_V;
        end
        
    end
    
end