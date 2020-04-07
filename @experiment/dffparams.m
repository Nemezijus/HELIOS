function E = dffparams(ex)
% E = dffparams(ex) - initializes dff parameter struct for given experiment
% object ex

E.median.long_kernel_coeff = 0.0468;
E.median.short_kernel_coeff = 8.7476e-04;

E.mode.mode_kernelsize = 5400;
E.mode.mean_kernelsize = 3000;

S = visc_recall_stims(ex.stim_type);
E.percentile.timewindow = S.static1*1e-3;
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
E.mean.S = S;
E.mean.setup = ex.setup;