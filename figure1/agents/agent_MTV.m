classdef agent_MTV
    
    properties
        alpha
        V
        L0
        w
        bias
        L
        previous_choice
    end
    
    properties (Constant)
        % Parameter bounds
        lb = [0, -inf, -inf, 0, -1];
        ub = [1, inf, inf, 1, 1];
    end
    
    properties (Dependent)
        agent_state
    end
    
    methods
        
        %% Constructor
        function self = agent_MTV(params)
            
            if ~exist('params','var')
                params = [0,0,0,0,0];
            end
           
            % Copy parameters as named properties
            self = self.set_params(params);
            
            % Initialize a new session
            self = self.new_sess;
        end
        
        %% Define generic "parameters" in terms of named internal variables
        function params = get_params(self)
            params = [self.alpha, self.V, self.L0, self.w, self.bias];
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
            self.V = params(2);
            self.L0 = params(3);
            self.w = params(4);
            self.bias = params(5);
        end
        
        %% Define "agent state" in terms of named internal variables
        % For this agent, it is L and previous choice
        
        
        function agent_state = get_agent_state(self)
            agent_state = [self.L, self.previous_choice];
        end
        
        function self = set_agent_state(self, agent_state)
            self.L = agent_state(1);
            self.previous_choice =  agent_state(2);
        end
        
        %% Methods
        %% New Session
        function self = new_sess(self)
            self.L = 0.5;
            self.previous_choice = 1; % left or right
        end
        
        %% Make choice
        function actionProbs = get_actionProbs(self) % returns probabilities of left and right
            
            Leff = (self.L - self.V)/self.w;
            
            if self.previous_choice ==1
                actionLogits(1) = Leff + self.bias;
                actionLogits(2) = 1 - Leff - self.bias;
            else
                actionLogits(1) = 1 - Leff + self.bias;
                actionLogits(2) = Leff - self.bias;
            end
            actionProbs = exp(actionLogits) / sum(exp(actionLogits));
            
        end
        
        function choice = make_choice(self) % returns left or right
            actionProbs = self.get_actionProbs;
            choice = (rand < actionProbs(1));
            choice = double(choice==0) + 1; % 1(left) or 2 (right)
            
        end
        
        %% Update
        function self = update(self, trial)
            
            % If this is the beginning of a new session, reset beliefs
            if trial.new_sess
                self = self.new_sess;
                
            end
            
            % Update L
            new_L = NaN;
            new_L =   self.alpha * self.L + (1-self.alpha) * trial.reward;
            
            if trial.choice ~= self.previous_choice
                self.L = self.L0;
            else
                self.L = new_L;
            end
            
            self.previous_choice = trial.choice;
            
        end
        
    end
end