function THR = significant_peaks(trace, xdata, sigma, S, tofilter, toplot)
% THR = significant_peaks(trace, xdata, sigma, S, tofilter, toplot) -
% threholds trace by 2*sigma and finds peaks of it above the threshold.
% part of HELIOS
if toplot
    figure;set(gcf,'units', 'normalized', 'position', [0.0208 0.508 0.954 0.389])
    plot(xdata, trace,'b-'); hold on
    plot([xdata(1), xdata(end)],[2*sigma, 2*sigma],'r-');
    plot([xdata(1), xdata(end)],[0.5*sigma, 0.5*sigma],'k-');
end
if tofilter
    trace = visc_gauss(trace,2);
end
if toplot
    plot(xdata, trace, 'c-','linew',3);
end
above_trace_filter = trace >= sigma*2; %logical filter
above_trace = trace(above_trace_filter);
cut_xdata = [];
if sum(above_trace_filter) > 0
    samplesidx = 1:numel(trace);
    x_above = xdata(above_trace_filter);
    if numel(x_above) > 1
        diff_x_above = diff(x_above);
        mode_diff_x_above = mode(diff_x_above);
        diff_x_above = [Inf, diff_x_above];
        x_critical_filter = diff_x_above > mode_diff_x_above;
        x_critical = x_above(x_critical_filter);
    else
        x_critical = x_above;
    end
    for icrit = 1:numel(x_critical)
        csample_orig = samplesidx(xdata==x_critical(icrit));
        csample = csample_orig;
        while trace(csample) >=0.5*sigma
            csample = csample-1;
            if csample == 0
                csample = 1;
                break
            end
        end
        cut_trace(icrit,1) = trace(csample);
        cut_xdata(icrit,1) = xdata(csample);
        csample = csample_orig;
        while trace(csample) >=0.5*sigma
            csample = csample+1;
            if csample > numel(xdata)
                csample = csample-1;
                break
            end
        end
        cut_trace(icrit,2) = trace(csample);
        cut_xdata(icrit,2) = xdata(csample);
    end
    final_cut_xdata = unique(cut_xdata,'rows');
    Xmask = zeros(size(xdata));
    Xmasknan = NaN(size(xdata));
    stimpeaks = 0;
    for icut = 1:numel(final_cut_xdata(:,1))
        Xmask(xdata>=final_cut_xdata(icut,1) & xdata <= final_cut_xdata(icut,2)) = 1;
        Xmasknan(xdata>=final_cut_xdata(icut,1) & xdata <= final_cut_xdata(icut,2)) = 1;
        X{icut} = xdata(xdata>=final_cut_xdata(icut,1) & xdata <= final_cut_xdata(icut,2));
        Y{icut} = trace(xdata>=final_cut_xdata(icut,1) & xdata <= final_cut_xdata(icut,2))';
        if min(X{icut}) >= S.static1 & min(X{icut}) <= S.blank2+1e3 %some lenience for post-stim response
            stimpeaks = stimpeaks+1;
        end
        if toplot
            plot(xdata(xdata>=final_cut_xdata(icut,1) & xdata <= final_cut_xdata(icut,2)),...
                trace(xdata>=final_cut_xdata(icut,1) & xdata <= final_cut_xdata(icut,2)),'r-','linew',3);
            yl = ylim;
            plot([S.static1, S.static1], yl, 'g-');
            plot([S.blank2, S.blank2], yl, 'g-');
        end
    end
end
if ~isempty(cut_xdata)
    THR.total_peaks = numel(cut_xdata(:,1));
    THR.unique_peaks = numel(final_cut_xdata(:,1));
    THR.stim_peaks = stimpeaks;
    THR.unique_cuts_X = X;
    THR.unique_cuts_Y = Y;
    THR.Xmasknan = Xmasknan;
else
    THR.total_peaks = 0;
    THR.unique_peaks = 0;
    THR.stim_peaks = 0;
    THR.unique_cuts_X = {};
    THR.unique_cuts_Y = {};
    THR.Xmasknan = NaN(size(xdata));
end
