classdef NeuropilSubtract
%     clear classes
    properties
        lam
        dt
        folds
        
        T
        T_f
        ab
        M
        
        F_M
        F_N
        
        r_vals
        error_vals
        r
        error
    end
    methods
        function obj = NeuropilSubtract(lam, folds, dt)
            if nargin < 3
                dt = 1.0;
            end
            if nargin < 2
                folds = 4;
            end
            if nargin < 1
                lam = 0.05;
            end
            
            obj.lam = lam;
            obj.dt = dt;
            obj.folds = folds;
            
            obj.T = 0;
            obj.T_f = [];
            
            obj.F_M = [];
            obj.F_N = [];
            
            obj.r_vals = [];
            obj.error_vals = [];
            obj.r = [];
            obj.error = [];
        end
        function obj = set_F(obj, F_M, F_N)
            %Break the F_M and F_N traces into the number of folds specified
            %in the class constructor and normalize each fold of F_M and R_N relative to F_N.
            F_M_len = numel(F_M);
            F_N_len = numel(F_N);
            
            if F_M_len ~= F_N_len
                error('F_M and F_N are not the same size!')
            end
            if obj.T ~= F_M_len
                %some logging stuff should be inserted here
                obj.T = F_M_len;
                obj.T_f = floor(obj.T / obj.folds);
                [obj.ab, obj.M] = ab_from_T(obj,obj.T_f, obj.lam, obj.dt);
            end
            obj.F_M = {};
            obj.F_N = {};
            for fi = 0: obj.folds-1
                obj.F_M{fi+1} = F_M((fi * obj.T_f)+1:(fi+1) * obj.T_f);
                obj.F_N{fi+1} = F_N((fi * obj.T_f)+1:(fi+1) * obj.T_f);
            end
        end
        
        function obj = fit_block_coordinate_desc(obj, r_init, min_delta_r)
            if nargin == 1
                r_init = 5;
                min_delta_r = 0.00000001;
            end
            F_M = [obj.F_M{:}];
            F_N = [obj.F_N{:}];
            
            r_vals = [];
            error_vals = [];
            r = r_init;
            
            delta_r = NaN;%or maybe something else other than NaN can fit here
            it = 0;
            ab = ab_from_T(obj,obj.T, obj.lam, obj.dt);
            while isnan(delta_r) | delta_r > min_delta_r
%                 F_C = solve_banded((1, 1), ab, F_M - r * F_N);%here need proper translation
            end
        end
        
        function obj = fit(obj,r_range, iterations, dr, dr_factor)
            if nargin == 2
                r_range = [0.0, 2.0];
                iterations = 3;
                dr = 0.1;
                dr_factor = 0.1;
            end
            global_min_error = NaN;
            global_min_r = NaN;
            r_vals = [];
            error_vals = [];
            
            it_range = r_range;
            it = 0;
            
            it_dr = dr;
            while it < iterations
%                 tic
%                 disp(['current iteration: ',num2str(it+1),' out of ', num2str(iterations)])
                it_errors = [];
                rs = [it_range(1):it_dr:it_range(2)]; rs = rs(1:end-1);
                for r = rs
                    error = estimate_error(obj, r);
                    it_errors = [it_errors,error];
                    r_vals = [r_vals, r];
                    error_vals = [error_vals, error];
                end
                [~, min_i] = min(it_errors);
                min_error = it_errors(min_i);
                if isnan(global_min_error) || min_error < global_min_error
                    global_min_error = min_error;
                    global_min_r = rs(min_i);
                end
                %here should be another logging case<<<>>>>>
                
                %if the minimum error is on the upper boundary,
                %extend the boundary and redo this iteration
                if min_i == length(it_errors)
                    %logging here too
                    it_range = [rs(end), rs(end) + (rs(end) - rs(1))];
                else
                    it_range = [rs(max(min_i - 1, 1)),rs(min(min_i + 1, length(rs) - 1))];
                    it_dr = it_dr .* dr_factor; %maybe dont need .
                    it = it + 1; %this affects the while loop
                end
%                 toc
            end
            obj.r_vals = r_vals;
            obj.error_vals = error_vals;
            obj.r = global_min_r;
            obj.error = global_min_error;
        end
        
        function errors = estimate_error(obj, r)
            errors = zeros(1,obj.folds);
            for fi = 1:obj.folds
                F_M = obj.F_M{fi};
                F_N = obj.F_N{fi};
                spF_M = sparse(1,numel(F_M));
                spF_M(1:end) = F_M;
                spF_N = sparse(1,numel(F_N));
                spF_N(1:end) = F_N;
                sp_result = sparse(numel(F_M),1);
                sp_result(1:end) = (F_M-(r.*F_N))';
                clear F_M F_N
                F_C = obj.M\sp_result;%(F_M-(r.*F_N))'; %solve_banded equivalent. Had to keep M value in obj.
                F_C = F_C';
                errors(fi) = abs(error_calc(obj,spF_M, spF_N, F_C, r));%might need higher precision here [8 significant digits in python]
            end
            errors = mean(errors);
        end
        
    end
    
end
















