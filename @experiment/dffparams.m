function E = dffparams(ex)
% E = dffparams(ex) - initializes dff parameter struct for given experiment
% object ex

E.median.long_kernel_coeff = 0.0468;
E.median.short_kernel_coeff = 8.7476e-04;

E.mode.mode_kernelsize = 5400;
E.mode.mean_kernelsize = 3000;

%added 2021-01-06 
if isempty(ex.stim_type)
    E.percentile.timewindow = 10; %first 10 seconds
else
%     S = visc_recall_stims(ex.stim_type);
    S = stimulus_protocol(ex.stimtype); 
    E.percentile.timewindow = S.static1*1e-3;
end
%till here
E.percentile.perc = 8;
E.percentile.catchoutlier = 1;

if strcmp(ex.setup, 'ao')
    E.gauss.doao = 1;
else
    E.gauss.doao = 0;
end
E.gauss.Gsmooth = 10;
E.gauss.nbins = 100;

E.mean.window = 500;
if isempty(ex.stim_type)
    E.mean.S = NaN;
else
    E.mean.S = S;
end
E.mean.setup = ex.setup;