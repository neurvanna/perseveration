classdef agent_bayes_habits_anna
    
    properties
%         % Parameters
        block_length_min
        block_length_max
        reward_prob_low
        reward_prob_high
        beta
        alpha_habit
        beta_habit
        % State variables
        beliefs
        H
    end
    
    properties (Constant)
        stan_file = '';
        % Parameter bounds
        lb = [0, 0, -inf];
        ub = [inf, 1, inf];
    end
    
    methods
        %% Constructor
        function self = agent_bayes_habits_anna(params)
            
            self.block_length_min=125;
            self.block_length_max=175;
            self.reward_prob_low=0.2;
            self.reward_prob_high=0.8;
            if ~exist('params', 'var')
                params = zeros(1, length(self.lb));
            end
            
            % Assign parameters
            %self.set_params(params);
            self = self.set_params(params);
            % Initialize a new session
            %self.new_sess;
            self = self.new_sess;
        end
        
         %% Define generic "parameters" in terms of named internal variables
        function params = get_params(self)
           params = [self.beta, self.alpha_habit, self.beta_habit]; 
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
            self.beta = params(1);
            self.alpha_habit = params(2);
            self.beta_habit = params(3);
        end
        
        %% Define generic "agent state" in terms of named internal variables
        % For this agent, it is the belief
        function agent_state = get_agent_state(self)
            agent_state = [self.beliefs(:); self.H];
        end
        
        function self = set_agent_state(self, agent_state)
            error('Not yet implemented')
        end
        
        %% New Session
        function self = new_sess(self)
%             self.block_length_min=125;
%             self.block_length_max=175;
%             self.reward_prob_low=0.2;
%             self.reward_prob_high=0.8;
            self.beliefs = 0.5*(1/self.block_length_max)*ones(2, self.block_length_max);
            self.H = 0;
        end
        
        %% Action Probabilities
        function actionProbs = get_actionProbs(self)
            
            % What is the probability that the current block is "0"
            p_left_better = sum(self.beliefs(1,:),2);

            Vl = p_left_better*self.reward_prob_high + (1-p_left_better)*self.reward_prob_low;
            Vr = (1-p_left_better)*self.reward_prob_high + p_left_better*self.reward_prob_low;
            Veff(1) = self.beta * [Vl] - self.beta_habit * self.H;
            Veff(2) = self.beta * [Vr] + self.beta_habit * self.H;

            %actionProbs = [logistic(-Veff(1)), logistic(Veff(2))];

            %actionProbs = [logistic(-1*Veff), logistic(Veff)];
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
                %self.new_sess;
                self = self.new_sess;
            end
            
            % First Bayesian Update
            pResultGivenLeftBetter = NaN;
            pResultGivenLeftWorse = NaN;
            p_left_better = sum(self.beliefs(1,:),2);
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
            
            pResult = (p_left_better * pResultGivenLeftBetter) + ...
                ((1-p_left_better) * pResultGivenLeftWorse);
            
            % Observation model: Posterior = Prior * Likelihood
            self.beliefs(1,:) = self.beliefs(1,:) * pResultGivenLeftBetter / pResult;
            self.beliefs(2,:) = self.beliefs(2,:) * pResultGivenLeftWorse / pResult;
            
            
            % Transition model
            % Advance all density by one trial.
            % Distribute density from last slot evenly to the first N
            % slots on the other block. 
            flip_window_length = self.block_length_max - self.block_length_min;

            final_density = self.beliefs(:,end);
            
            self.beliefs = [zeros(2,1), self.beliefs(:,1:end-1)];

            self.beliefs(1,1:flip_window_length) = self.beliefs(1,1:flip_window_length) + final_density(2) / flip_window_length;
            self.beliefs(2,1:flip_window_length) = self.beliefs(2,1:flip_window_length) + final_density(1) / flip_window_length;

            eps= 1e-10;
            self.beliefs = self.beliefs / sum(self.beliefs(:));
            assert(abs(sum(self.beliefs(:)) - 1) < eps)
            %self.pLeftBetter = (1 - 0.02) * self.pLeftBetter + self.flip_prob * (1 - self.pLeftBetter);
            
            
            choice_for_learning = 2 * (trial.choice - 1.5); % Choice as -1 left, +1 right
            self.H = (1 - self.alpha_habit) * self.H + self.alpha_habit * choice_for_learning;
        end
        
        
        
    end
end