function [corrected, NP] = neuropil_contamination_correction(data, neuropil, toplot)
% neuropil_contamination_correction(data, neuropil, toplot) - estimates neuropil contamination
% ratio in the data and outputs the corrected version of the data.
% data - the uncorrected trace
% neuropil - measured neuropil trace
% corrected - the corrected data trace
% part of HELIOS.
if nargin == 2
    toplot = 0;
end

[NP, ns] = estimate_contamination_ratios(data, neuropil);
corrected = data - NP.r .* neuropil;

if toplot
    f = figure;
    set(f,'units', 'normalized', 'position', [0.22 0.356 0.619 0.453]);
    plot(data,'k-','linew',2); hold on
    plot(neuropil, 'b-','linew', 2);
    plot(corrected,'r-','linew',2);
    xlabel('samples');
    ylabel('intensity, a.u.');
    legend({'raw','neuropil','corrected'});
    text(0.05,0.85,['r = ', num2str(NP.r)],'units','normalized');
end