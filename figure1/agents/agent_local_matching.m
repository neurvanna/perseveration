classdef agent_local_matching
    
    properties
        % Parameters
        alpha
        % State variables
        Q
    end
    
    properties (Constant)
        stan_file = '';
        % Parameter Bounds
        lb = [0];
        ub = [1];
    end
    
    methods
        
        %% Constructor
        function self = agent_local_matching(params)
            if ~exist('params', 'var')
                params = zeros(1, length(self.lb));
            end
            % Assign parameters
            self = self.set_params(params);
            self = self.new_sess;
        end
        %% Define generic "parameters" in terms of named internal variables
        function params = get_params(self)
            params = [self.alpha];
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
        end
        
        %% Define generic "agent state" in terms of named internal variables
        % For this agent, it is just Q
        function agent_state = get_agent_state(self)
            agent_state = self.Q;
        end
        
        function self = set_agent_state(self, agent_state)
            self.Q = agent_state;
        end
        
        %% New Session
        function self = new_sess(self)
            self.Q = [0.5, 0.5];
        end
        
        %% Make choice
        function actionProbs = get_actionProbs(self)
            actionProbs = self.Q / sum(self.Q);
        end
        
        function choice = make_choice(self)
            action_probs = self.get_actionProbs;
            choice = rand < action_probs(1);
            choice = double(choice==0) + 1; % Choice as 1 or 2
        end
        
        %% Update
        function self = update(self, trial)
            
            % If this is the beginning of a new session, reset beliefs
            if trial.new_sess
                self = self.new_sess;
            end
            
            chosen = trial.choice; % Choice will be 1 or 2
            unchosen = (trial.choice==1) + 1; % Converts 1 or 2 into 2 or 1
            
            new_Q = [NaN, NaN];
            new_Q(chosen) =   (1 - self.alpha)   * self.Q(chosen)   + self.alpha * trial.reward;
            new_Q(unchosen) = (1 - self.alpha) * self.Q(unchosen);
            
            self.Q = new_Q;
            
        end
    end
    
end