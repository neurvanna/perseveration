classdef agent_bayes_flips_habits
    
    properties
        % Parameters
        beta
        reward_prob_low
        reward_prob_high
        flip_prob
        alpha_habit
        beta_habit
        % State variables
        pLeftBetter
        H
    end
    
    properties (Constant)
        stan_file = '';
        % Parameter Bounds
        lb = [0, 0, 0, -inf, 0, -inf];
        ub = [1, 1, 1, inf, inf, inf];
    end
    
    methods
        %% Constructor
        function self = agent_bayes_flips_habits(params)
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
           params = [self.reward_prob_low, self.reward_prob_high, self.flip_prob, self.beta, self.alpha_habit, self.beta_habit]; 
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
            
            self.reward_prob_low = min(params(1:2)); % The low reward probability is which ever is lower
            self.reward_prob_high = max(params(1:2)); % The high reward probability is whichever is higher
            self.flip_prob = params(3);
            self.beta = params(4);
            self.alpha_habit = params(5);
            self.beta_habit = params(6);
        end
        
        %% Define generic "agent state" in terms of named internal variables
        % For this agent, it is just Q
        function agent_state = get_agent_state(self)
            agent_state = [self.pLeftBetter, self.H];
        end
        
        function self = set_agent_state(self, agent_state)
            % Ensure agent_state is between 0 and 1
            agent_state = min(agent_state, 1);
            agent_state = max(agent_state, 0);
            
            self.pLeftBetter = agent_state;
        end
        
        %% New Session
        function self = new_sess(self)
            self.pLeftBetter = 0.5;
            self.H = 0;
        end
        
        %% Action Probabilities
        function actionProbs = get_actionProbs(self)
            
            Vl = self.pLeftBetter*self.reward_prob_high + (1-self.pLeftBetter)*self.reward_prob_low;
            Vr = (1-self.pLeftBetter)*self.reward_prob_high + self.pLeftBetter*self.reward_prob_low;
            Veff = self.beta * [Vl,Vr];
            Veff(1) = Veff(1) + self.beta_habit * self.H;
            Veff(2) = Veff(2) - self.beta_habit * self.H;
            
            actionProbs = exp(Veff) / sum(exp(Veff));
        end
        
        
        %% Make choice
        function choice = make_choice(self)
            actionProbs = self.get_actionProbs;
            choice = (rand < actionProbs(1));
            choice = double(choice==0) + 1; % Choice as 1 or 2
        end
        
        %% Learning Rule
        function self = update(self, trial)
            
            % If this is the beginning of a new session, reset beliefs
            if trial.new_sess
                self = self.new_sess;
            end
            
            % First Bayesian Update
            pResultGivenLeftBetter = NaN;
            pResultGivenLeftWorse = NaN;
            % Likelihood
            if trial.choice == 1 % If chose left
                if trial.reward == 1
                    pResultGivenLeftBetter = self.reward_prob_high;
                    pResultGivenLeftWorse = self.reward_prob_low;
                else
                    pResultGivenLeftBetter = (1-self.reward_prob_high);
                    pResultGivenLeftWorse = (1-self.reward_prob_low);
                end
            elseif trial.choice == 2 % If chose right
                if trial.reward == 1
                    pResultGivenLeftBetter = self.reward_prob_low;
                    pResultGivenLeftWorse = self.reward_prob_high;
                else
                    pResultGivenLeftBetter = (1-self.reward_prob_low);
                    pResultGivenLeftWorse = (1-self.reward_prob_high);
                end
            end
            
            pResult = (self.pLeftBetter * pResultGivenLeftBetter) + ...
                ((1-self.pLeftBetter) * pResultGivenLeftWorse);
            
            % Posterior = Prior * Likelihood
            self.pLeftBetter = self.pLeftBetter * pResultGivenLeftBetter / pResult;
            
            
            % Then add possibility for flip
            self.pLeftBetter = (1 - self.flip_prob) * self.pLeftBetter + self.flip_prob * (1 - self.pLeftBetter);
            
            choice_for_learning = 2 * (trial.choice - 1.5); % Choice as -1 left, +1 right
            
            self.H = (1 - self.alpha_habit) * self.H + self.alpha_habit * choice_for_learning;
            


        end
        
        
        
    end
end