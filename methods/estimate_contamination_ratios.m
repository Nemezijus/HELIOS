function [NP, ns] = estimate_contamination_ratios(F_M, F_N,lam, folds, iterations,r_range, dr, dr_factor)
% estimate_contamination_ratios - calculates neuropil contamination ratio
% in the data signal. The ratio itself is stored in NP.r field.
% F_M - the data signal to be corrected
% F_N - the neuropil signal, measured from the annulus of ~10um around ROI
% other parameters are optional
% part of HELIOS
if nargin == 2
    lam = 0.05;
    folds = 4;
    iterations = 3;
    r_range = [0.0, 2.0];
    dr = 0.1;
    dr_factor = 0.1;
end

ns = NeuropilSubtract(lam, folds); %this is an object
ns = ns.set_F(F_M, F_N);
ns = ns.fit(r_range,iterations,dr,dr_factor);

NP.r = ns.r;
NP.r_vals = ns.r_vals;
NP.err = ns.error;
NP.err_vals = ns.error_vals;
NP.min_error = ns.error;
NP.it = length(ns.r_vals);

                                  