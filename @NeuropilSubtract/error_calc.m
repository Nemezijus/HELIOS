function er = error_calc(obj,F_M, F_N, F_C, r)
% error_calc - a NeuropilSubtract class method
% part of HELIOS 
p = power(F_C - (F_M - (r.* F_N)),2);
er = sqrt(mean(p))./mean(F_M);