%% This is a template for constructing new agents. Everywhere there is ALL CAPS you have a job to do. 

%%
classdef template % REPLACE THIS WITH THE NAME OF THE AGENT
    
    properties
        % Parameters
        % SPECIFY THE NAMES OF THIS AGENT'S PARAMETERS e.g. alpha, beta
        
        % State Variables
        % SPECIFY THE NAMES OF THIS AGENT'S STATE VARIABLES e.g. Q
    end
    
    properties (Constant)
        stan_file = ''; % PROVIDE A PATH TO THE STAN FILE FOR THIS AGENT
        % Parameter Bounds
        lb = % SPECIFY PARAMETER LOWER BOUNDS e.g. [0, -inf];
        ub = % SPEFICY PARAMETER UPPER BOUNDS e.g. [1, inf];
    end
    
    methods
        
        %% Constructor
        function self = AGENT_NAME(params) %% REPLACE THIS WITH THE NAME OF THE AGENT
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
            n_params = % SPECIFY HOW MANY PARAMETERS THIS AGENT HAS
            if isempty(params)
                params = zeros(1, n_params);
            end
            assert(length(params) == n_params, ['This agent requires exactly ', num2str(n_params), ' parameters')
            assert(isnumeric(params), 'Params must all be numeric')
            
            % Check params are within bounds
            assert(all(params >= self.lb) && all(params <= self.ub),...
                'One or more of the parameters specified is out of bounds');
            
            % COPY PARAMETERS INTO NAMED PROPERTIES
            
        end
        
        %% Define generic "agent state" in terms of named internal variables
        % For this agent, it is just Q
        function agent_state = get_agent_state(self)
            % RETURN agent_state BASED ON NAMED INTERNAL STATE VARIABLES
        end
        
        function self = set_agent_state(self, agent_state)
            % SET NAMED AGENT STATE VARIABLES TO VALUES GIVEN IN
            % agent_state
        end
        
        %% Define action probabilities
        function actionProbs = get_actionProbs(self)
            % RETURN actionProbs AS A TWO-ELEMENT VECTOR WITH PROBABILITIES
            % THAT SUM TO ONE
        end
        
        %% New Session
        function self = new_sess(self)
            % RESET STATE VARIABLES TO DEFAULT VALUES
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
            
            % UPDATE STATE VARIABLES APPROPRIATELY
            
        end
 
    end
end