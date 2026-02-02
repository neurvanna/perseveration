classdef agent_bayes_drifts
    
    properties
        % Parameters
        beta
        sigma
        % Internal convenience variables
        kernel
        Pn
        resolution
        % Agent State variables
        pPr
        pPl
        
    end
    
    properties (Constant)
        stan_file = '';
        % Parameter Bounds
        lb = [-inf, 0];
        ub = [ inf, inf];
    end
    
    methods
        %% Constructor
        function self = agent_bayes_drifts(params, resolution)
            
            if ~exist('params', 'var')
                params = zeros(1, length(self.lb));
            end
            
            % If the resolution is not specified, set it to a reasonable default
            if ~exist('resolution', 'var')
                resolution = 101;
            end
            % Resolution must be an odd number for the code below to work
            if mod(resolution,2) == 0
                resolution = resolution + 1;
            end
            
            self.resolution = resolution;
            self.Pn = 0:1/(self.resolution-1):1;
            
            % Assign parameters
            self = self.set_params(params);
            % Initialize a new session
            self = self.new_sess;        
        end
        
         %% Define generic "parameters" in terms of named internal variables
        function params = get_params(self)
           params = [self.beta, self.sigma]; 
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
            
            self.beta = params(1);
            self.sigma = params(2);
            
            % Initialize the assumed (by the agent) smoothing kernel
            self.kernel = (1/(self.sigma*sqrt(2*pi))) * exp(-0.5*((self.Pn-0.5)/self.sigma).^2);     
            
        end
        
        %% Define generic "agent state" in terms of named internal variables
        function agent_state = get_agent_state(self)
            agent_state = [self.pPl; self.pPr];
        end
        
        function self = set_agent_state(self, agent_state)
            self.pPl = agent_state(1,:);
            self.pPr = agent_state(2,:);
        end
        
        %% Reset for new session
        function self = new_sess(self)
            self.pPr = ones(1, self.resolution) / self.resolution;
            self.pPl = ones(1, self.resolution) / self.resolution; 
        end
        
        %% Make choice
        function choice = make_choice(self)
            actionProbs = self.get_actionProbs;
            choice = (rand < actionProbs(1));
            choice = double(choice==0) + 1; % Choice as 1 or 2
        end
        
        
        %% Compute action probabilities, given current beliefs
        function actionProbs = get_actionProbs(self)
            Vl = self.pPl * self.Pn';        
            Vr = self.pPr * self.Pn';
            Veff = self.beta * [Vl, Vr];
            
            % Choose a side
            actionProbs = exp(Veff) / sum(exp(Veff));
       
        end
        
        %% Update beliefs given evidence
        function self = update(self, trial)
            
            % If this is the beginning of a new session, reset beliefs
            if trial.new_sess
                self = self.new_sess;
            end
            
            % First Bayesian Update
            if trial.reward == 1
                pResultGivenPn = self.Pn;
            else
                pResultGivenPn = 1-self.Pn;
            end
            
            Vl = self.pPl * self.Pn';        
            Vr = self.pPr * self.Pn';
            
            if trial.choice == 1
                self.pPl = (pResultGivenPn .* self.pPl) / Vl;
            elseif trial.choice == 2
                self.pPr = (pResultGivenPn .* self.pPr) / Vr;
            end
            
            % Then add drift, cropping the edges
            pPl_drifted = conv(self.pPl, self.kernel,'full');
            pPr_drifted = conv(self.pPr, self.kernel,'full');
            pads = (length(pPr_drifted) - length(self.pPr))/2;
            
            % nudge anyone who drifted off the edge back to the edge
            self.pPr = pPr_drifted((pads+1):end-pads);
            self.pPr(1) = self.pPr(1) + sum(pPr_drifted(1:pads));
            self.pPr(end) = self.pPr(end) + sum(pPr_drifted((end-pads+1):end));
            
            self.pPl = pPl_drifted((pads+1):end-pads);
            self.pPl(1) = self.pPl(1) + sum(pPl_drifted(1:pads));
            self.pPl(end) = self.pPl(end) + sum(pPl_drifted((end-pads+1):end));
            
            % and normalize
            self.pPl = self.pPl / sum(self.pPl);
            self.pPr = self.pPr / sum(self.pPr);
            
            
        end
        
    end
        
end