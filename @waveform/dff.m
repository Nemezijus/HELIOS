function [obj, dff] = dff(obj, method, E)
% [obj, dff] = dff(obj, method, E) - performs dff on the waveform object using
% specified method
% valid methods are - 'median', 'mode', 'mean' [the old method],
% 'percentile', 'gauss'
% E - experiment object which provides information for some dff methods
% part of HELIOS
className = class(obj);
if ~strcmp(className, 'waveform')
    error('the provided object is not a waveform!')
    return
end
if nargin < 3
    E = [];
end
if nargin < 2
    method = 'median';
end

switch method
    case 'median'
        [~,dff] = median_dff(obj,E);
        obj.data = dff;
        obj.data_type = 'dff';
        obj.data_units = '%';
    case 'mode'
        [~, dff] = mode_dff(obj,E);
        obj.data = dff;
        obj.data_type = 'dff';
        obj.data_units = '%';
    case 'mean'
        [~, dff] = mean_dff(obj, E);
        obj.data = dff;
        obj.data_type = 'dff';
        obj.data_units = '%';
    case 'percentile'
        [~, dff] = percentile_dff(obj,E);
        obj.data = dff;
        obj.data_type = 'dff';
        obj.data_units = '%';
    case 'gauss'
        [~, dff] = gauss_dff(obj, E);
        obj.data = dff;
        obj.data_type = 'dff';
        obj.data_units = '%';
    otherwise
        error('no valid method specified [median, mode, mean, percentile, gauss]');
end


function [obj, DFF] = median_dff(obj,E)
if isempty(E)
    long_kernel_coeff = 0.0468;
    short_kernel_coeff = 8.7476e-04;
else
    long_kernel_coeff = E.median.long_kernel_coeff;
    short_kernel_coeff = E.median.short_kernel_coeff;
end
DFF = obj.data;
for irow = 1:numel(DFF(:,1))
    dff = DFF(irow,:);
    long_kernel = floor(long_kernel_coeff*numel(dff));
    short_kernel = floor(short_kernel_coeff*numel(dff));
    sigma_f = noise_std(dff);
    %long timescale median filter for baseline subtraction
    tf_long = medfilt1(dff,long_kernel);
    dff = dff - tf_long;
    dff = dff./(max(tf_long, sigma_f));
    %short timescale detrending
    sigma_dff = noise_std(dff);
    tf_short = medfilt1(dff, short_kernel);
    tf_short = min(tf_short, 2.5*sigma_dff);
    dff = dff - tf_short;
    DFF(irow,:) = dff;
end

function [obj, DFF] = mode_dff(obj,E)
if isempty(E)
    mode_kernelsize=5400;
    mean_kernelsize=3000;
else
    mode_kernelsize = E.mode.mode_kernelsize;
    mean_kernelsize = E.mode.mean_kernelsize;
end
DFF = obj.data;
for irow = 1:numel(DFF(:,1))
    dff = DFF(irow,:);
    if mode_kernelsize >= numel(dff)
        mode_kernelsize = fix(numel(dff)/2);
%         disp(['mode_kernelsize changed to ', num2str(mode_kernelsize)])
    end
    if mean_kernelsize >= numel(dff)
        mean_kernelsize = fix(numel(dff)/4);
%         disp(['mean_kernelsize changed to ', num2str(mean_kernelsize)])
    end
    if mode_kernelsize == 0 || mean_kernelsize == 0
        error ('Kernel size is 0!')
    end
    modeline = zeros(size(dff));
    modelineLP = zeros(size(dff));
    
    modeline = movingmode_fast(dff, mode_kernelsize, modeline);
    modelineLP = movingaverage(modeline, mean_kernelsize, modelineLP);
    DFF(irow,:) = (dff - modelineLP)./ modelineLP;
end

function [obj, dff] = percentile_dff(obj,E)
%time units fixed
tu = obj.time_units;
switch tu
    case 's'
        X = obj.time;
    case 'ms'
        X = obj.time.*1e-3;
    case 'us'
        X = obj.time.*1e-6;
    otherwise
        error(['time units ',obj.time_units,' are not valid for percentile method. Please provide valid time axis and units (us, ms, s)']);
end
if nargin < 2
    E = [];
end
if isempty(E)
%     twdw = 9;
    twdw = prctile(X,25);
    perc = 8;
    catchoutlier = 1;
else
    twdw = E.percentile.timewindow;%still gonna change this
    perc = E.percentile.perc;
    catchoutlier = E.percentile.catchoutlier;
end
Y = obj.data;

Tsamp = (X(2) - X(1));
fps = 1/Tsamp;
wdw = round(fps*twdw);
numFrames = size(Y,2);
numCells = size(Y,1);
Y = Y';
smoothBaseline = zeros(size(Y));
if numFrames > 2*wdw
    for itrace = 1:numCells
        dataSlice = Y(:,itrace);
        temp = zeros(numFrames-2*wdw,1);
        for idx = wdw+1:numFrames-wdw
            temp(idx-wdw) = prctile(dataSlice(idx-wdw:idx+wdw),perc);
        end
        smoothBaseline(:,itrace)=[temp(1)*ones(wdw,1) ; temp; temp(end)*ones(wdw,1)];
        smoothBaseline(:,itrace)=visc_runfit(smoothBaseline(:,itrace),wdw,1);
    end
else
    for itrace = 1:numCells
        smoothBaseline(:,itrace) = [ones(numFrames,1)*prctile(Y(:,itrace),8)];
    end
end

dff = (Y - smoothBaseline)./smoothBaseline;
dff = dff';
[dff, sigma, mu] = visc_dffnoise(dff, catchoutlier);

function [obj, dff, sigma] = gauss_dff(obj, E)
if nargin == 1
    E = [];
end
if isempty(E)
    doao = 0;
    Gsmooth = 10;
    flag = [];
    nbins = 100;
else
    doao = E.gauss.doao;
    Gsmooth = E.gauss.Gsmooth;
    nbins = E.gauss.nbins;
end
Y = obj.data;
Yn = [];
tu = obj.time_units;
switch tu
    case 's'
        X = obj.time;
    case 'ms'
        X = obj.time.*1e-3;
    case 'us'
        X = obj.time.*1e-6;
    otherwise
        error(['time units ',obj.time_units,' are not valid for gauss method. Please provide valid time axis and units (us, ms, s)']);
end

Fs = 1/((X(2)-X(1))); %sampling rate Hz
%added 2019 05 22 for testing
if doao
    time_axis = X;
    Ytemp = Y;
    Tsamp = time_axis(2)-time_axis(1);
    cutoff = 500;%ms
    %             time_axis_cutoff = time_axis(end) - cutoff;
    N_cutoffsampl = ceil(cutoff/Tsamp);%how many samples from the end have to be 'treated'
    Ytemp(end-N_cutoffsampl:end) = deal(Ytemp(end-N_cutoffsampl-1));
    [N,edges] = histcounts(Ytemp, nbins);
end

%1 - histogram count
if ~doao
    [N,edges] = histcounts(Y, nbins);
end
centers = mean([edges(1:end-1);edges(2:end)]); %center points of the bins

%2 - smoothen the curve, find the dominant peak and neighboring trough
smoothN = smoothdata(N,'gaussian',Gsmooth);

[pks,pks_locs,pks_w,pks_p] = findpeaks(smoothN,'MinPeakProminence',2);
if isempty(pks)
    pks = max(smoothN);
    pksidx = 1:numel(smoothN);
    pks_locs = pksidx(smoothN == pks);
end
% dompkloc = centers(pks_locs(pks == max(pks)));
dompkloc = centers(pks_locs(1));
dompkidx = pks_locs(1);
% dompkidx = pks_locs(pks == max(pks));
if numel(dompkloc) > 1
    dompkloc = dompkloc(1); %if more than one dominant peak, take the leftmost one
end


%find troughs
if numel(pks) > 1
    between_peaks = centers(pks_locs);
    [tro,tro_locs,tro_w,tro_p] = findpeaks(-smoothN,'MinPeakProminence',2);
    tro_idxs = tro_locs;
    tro_locs = centers(tro_locs);%overwrite
end
%finding X and Y values for Gauss fit window
if numel(pks) > 1 %if theres more than 1 peak, there will always be a trough between two peaks
    pks_tro_diff = abs(tro_locs-dompkloc);
    cutoff_tro = tro_locs(pks_tro_diff == min(pks_tro_diff)); %this trough point will be a cutoff for Gauss fit
    cutoff_tro_idx = tro_idxs(pks_tro_diff == min(pks_tro_diff));
    if  numel(cutoff_tro) > 1 %lots of peaks lead to matching distances %numel(pks_tro_diff) > 3 |
        fitting_X = centers;
        fitting_Y = N;
    elseif abs(cutoff_tro_idx - dompkidx) > numel(smoothN)/4 & dompkidx < numel(smoothN)/2 %if the trough is very far from the first dominant peak
        fitting_X = centers(1:dompkidx+dompkidx-1);
        fitting_Y = N(1:dompkidx+dompkidx-1);
    else
        fitting_X = centers(centers<=cutoff_tro);
        fitting_Y = N(1:numel(fitting_X));
    end
    %when there is only one peak and its very close to the left side
elseif numel(pks) == 1 & pks_locs < numel(smoothN)/4
    if pks_locs <3 %if the very first 3 samples is the peak
        fitting_X = centers(1:5);
        fitting_Y = N(1:5);
    else
        fitting_X = centers(1:pks_locs+pks_locs-1);
        fitting_Y = N(1:pks_locs+pks_locs-1);
    end
elseif numel(pks) == 1 & pks_locs > numel(smoothN)/4 & pks < max(smoothN)%one peak but far from left
    fitting_X = centers(1:15);
    fitting_Y = N(1:15);
    %below added 2019-09-11
elseif numel(pks) == 1 & pks_locs < numel(smoothN)/2 %if in the first half
    fitting_X = centers(1:pks_locs+pks_locs-1);
    fitting_Y = N(1:pks_locs+pks_locs-1);
    %till here
else %we use the whole histogram
    fitting_X = centers;
    fitting_Y = N;
end

%2 - Gauss fit
%here we use previously estimated fitting_X and fitting_Y for fitting
try
[cfit, ~,out] = fit(fitting_X.',fitting_Y.','gauss1');
CO = coeffvalues(cfit);
gfit= @(t,a,b,c) a*exp(-((t-b)/c).^2);
currfit = gfit(fitting_X, CO(1),CO(2),CO(3));

m = CO(2); sigma = CO(3); %end result - mean and sd of the fit
catch
    disp('Gauss Fit did not work out, using artificial mean and sigma values')
    m = dompkloc;
    sigma = 0.1*m;
end
if m > max(Y)
    m = dompkloc;
    sigma = 0.1*m;
end
%3 cutting off data by threshold
thr_coeff = 2;
thr = m + thr_coeff*sigma;
if doao
    Ycut = Ytemp;
else
    Ycut = Y;
end
Ycut(Ycut > thr) = thr;
M = movmean(Ycut,100);%control the moving average window
% M = visc_gauss(Ycut,10);M = M';

%4 normalize waveform by the estimated moving mean
dff = Y./M - 1;

function [obj, dff] = mean_dff(obj, E)

Y = obj.data;
tu = obj.time_units;
switch tu
    case 's'
        X = obj.time*1e3;
    case 'ms'
        X = obj.time;
    case 'us'
        X = obj.time.*1e-3;
    otherwise
        error(['time units ',obj.time_units,' are not valid for gauss method. Please provide valid time axis and units (us, ms, s)']);
end
if isempty(E)
    window = 500; %ms
    S.static1 = max(X);
    S.blank2 = 0;
    setup = 'reso';
else
    window = E.mean.window;
    S = E.mean.S;
    setup = E.mean.setup;
end
tsample = X(2) - X(1); %ms
windowsamp = ceil(window./tsample); %the size of the sliding window for average
FULLidx = 1:numel(X);
%HERE WE REMOVE THE PARTS OF TRACES WHICH ARE IN THE FIRST SECOND OF
%RECORDING AND DURING VISUAL STIMULUS
%----


%AO addition 2017-08-07
%the last half second contains background measurement, we shift the curve
%by the average value of that 0.5s measurement. Then we exclude the last
%0.6 second from the rest of the recordings and proceed with normal df/f
if strcmp(setup,'ao')
    bgaodur = 400; %ms (half second)
    ignoreaodur = 600; %ms
    bgaoX = max(X) - bgaodur;
    ignoreaoX = max(X) - ignoreaodur;
    bgaomask = X > bgaoX & X < max(X);
    ignoreaomask = X > ignoreaoX & X <= max(X);
    
    bgaoY = Y(bgaomask);
    meanbgaoY = nanmean(bgaoY);
    if isnan(meanbgaoY)
        meanbgaoY = 0;
    end
    Y = Y - meanbgaoY; %at this point dataY for AO is adjusted to 0
else
    ignoreaomask = ~(X<= max(X));
end

%---------masks
mask1 = X > 1e3;%excluding the first second 
mask2 = X < S.static1;
mask3 = X > S.blank2 & ~ignoreaomask; %updated for AO on 2017-08-07
mask = mask1&mask2|mask3;

MASK_1 = mask1&mask2;
MASK_2 = mask3;
%---------




%MASK_1 scanning
dataX_M1 = X(MASK_1);
dataY_M1 = Y(MASK_1);
M1_idx = FULLidx(MASK_1);
firstsample = M1_idx(1);
lastsample = M1_idx(end);

Nsampl_M1 = numel(dataX_M1);

samplecount = 1;
while firstsample + windowsamp < lastsample
    nextsample = firstsample + windowsamp;
    dataYsample = Y(firstsample:nextsample);
    meanYsample(samplecount) = mean(dataYsample);
    fs(samplecount) = firstsample;
    ls(samplecount) = nextsample;
    samplecount = samplecount+1;
    firstsample = firstsample+1;
end
mindataYmean1 = min(meanYsample);
minmeanidx1 = meanYsample == min(meanYsample);
FS1 = fs(minmeanidx1);
LS1 = ls(minmeanidx1);
clear fs ls meanYsample

%MASK_2 scanning
if sum(MASK_2) > 0
dataX_M2 = X(MASK_2);
dataY_M2 = Y(MASK_2);
M2_idx = FULLidx(MASK_2);
firstsample = M2_idx(1);
lastsample = M2_idx(end);

Nsampl_M2 = numel(dataX_M2);

samplecount = 1;
while firstsample + windowsamp < lastsample
    nextsample = firstsample + windowsamp;
    dataYsample = Y(firstsample:nextsample);
    meanYsample(samplecount) = mean(dataYsample);
    fs(samplecount) = firstsample;
    ls(samplecount) = nextsample;
    samplecount = samplecount+1;
    firstsample = firstsample+1;
end
mindataYmean2 = min(meanYsample);
minmeanidx2 = meanYsample == min(meanYsample);
FS2 = fs(minmeanidx2);
LS2 = ls(minmeanidx2);
else
    mindataYmean2 = Inf;
end

%comparing the results of the two intervals above
if mindataYmean2 > mindataYmean1
    FS = FS1;
    LS = LS1;
    mindataYmean = mindataYmean1;
elseif mindataYmean2 < mindataYmean1
    FS = FS2;
    LS = LS2;
    mindataYmean = mindataYmean2;
else
    warning ('both intervals share the same minimum');
    mindataYmean = mindataYmean1;
    FS = FS1;
    LS = LS1;
end


if numel(FS) > 1
    FS = FS(1); %in case there are several minimum points with the same value, we choose the first interval
    LS = LS(1);
end

FSt = FS*tsample;
LSt = LS*tsample;
dff = (Y - mindataYmean)./mindataYmean;

%---------------MEDIAN HELPING FUNCTIONS------------------%
function nstd = noise_std(x, noise_kernel_length, positive_peak_scale,outlier_std_scale)
if nargin < 2
    noise_kernel_length = 31;
end
if nargin < 3
    positive_peak_scale = 1.5;
end
if nargin < 4
    outlier_std_scale = 2.5;
end

x = x - medfilt1(x, noise_kernel_length);
x = x(x < positive_peak_scale.*abs(min(x)));
rstd = robust_std(x);
x = x(abs(x) < outlier_std_scale*rstd);
nstd = robust_std(x);

function rstd = robust_std(x)
GAUSSIAN_MAD_STD_SCALE = 1.4826; %HARDCODED
median_absolute_deviation = median(abs(x - median(x)));
rstd = GAUSSIAN_MAD_STD_SCALE.*median_absolute_deviation;

%---------------MODE HELPING FUNCTIONS------------------%
function y = movingmode_fast(x, kernelsize, y)
% offset so that the trace is non-negative
minval = min(min(x), 0);
if minval < 0
    x = x - minval;
    
end
maxval = max(x);
% compute a histogram of a half kernel
halfsize = round(kernelsize / 2);
X = uint32(round(x(1:halfsize)));
[histo,edges] = histcounts(X,[0:floor(maxval+2)]);
% find the mode of the first half kernel
[~, mode] = max(histo);
mode = mode-1; %compensating Python 0 indexing
for m = 0:halfsize-1
    q = python_round(x(halfsize + m + 1));
    histo(q+1) = histo(q+1)+1;
    if histo(q+1) > histo(mode+1)
        mode = q;
    end
    y(m+1) = mode;
end
for m = halfsize: numel(x) - halfsize -1
    m = m+1;

    p = python_round(x(m - halfsize));

    histo(p+1) = histo(p+1) - 1;
    % need to find possibly new mode value
    if p == mode
        [~, mode] = max(histo); mode = mode-1;
    end
    q = python_round(x(m + halfsize));
    histo(q+1) = histo(q+1)+1;
    
    if histo(q+1) > histo(mode+1)
        mode = q;
    end
    y(m) = mode;
    
end

for m = numel(x) - halfsize : numel(x)-1
    m = m+1;
    p = python_round(x(m - halfsize));
    histo(p+1) = histo(p+1) - 1;
    
    % need to find possibly new mode value
    if p == mode
        [~, mode] = max(histo); mode = mode-1;
    end
    y(m) = mode;
end
% undo the offset
if minval < 0
    y = y + minval;
end

function y = movingaverage(x, kernelsize, y)

halfsize = round(kernelsize / 2);
sumkernel = sum(x(1:halfsize));%maybe+1 since in Python it starts from 0
for m = 1 : halfsize
    sumkernel = sumkernel + x(m + halfsize);
    y(m) = sumkernel / (halfsize + m-1);
end

sumkernel = sum(x(1:kernelsize));
for m = halfsize+1: numel(x) - halfsize
    sumkernel = sumkernel - x(m - halfsize) + x(m + halfsize);
    y(m) = sumkernel / kernelsize;
end

for m = numel(x) - halfsize +1 : numel(x)
    sumkernel = sumkernel - x(m - halfsize);
    y(m) = sumkernel / (halfsize - 1 + (numel(x) - m+1));
end

function r = python_round(n)
if mod(n,1) ~= 0.5
    r = round(n);
else
    if mod(n - mod(n,1),2) == 0
        r = floor(n);
    else
        r = ceil(n);
    end
    
end
%-----------------------PERCENTILE HELPING FUNCTIONS-----------------
function [dff, sigma, mu] = visc_dffnoise(dff, catchoutlier)
% [dff, sigma] = visc_dffnoise(dff) - estimate the noise in df/f signal
% and adjust it. Based on
% https://github.com/zebrain-lab/Toolbox-Romano-et-al/blob/master/Toolbox%20software/EstimateBaselineNoise.m
if nargin == 1
    catchoutlier = 0;
end
toplot = 0;
sigma = [];
thr = 0.2;
%catchoutlier
if catchoutlier
%     disp('Catching Outliers');
    isoutl = isoutlier(dff,'mean');
%     disp([num2str(sum(isoutl)), ' outliers found']);
    newmax = max(dff(~isoutl));
    [f,xi] = ksdensity(dff,linspace(min(dff), newmax, 100));
else
    [f,xi] = ksdensity(dff);
end
[peak,idx_peak] = max(f);
xtofit = xi(1:idx_peak);
ytofit = f(1:idx_peak);%./numel(f);
[A,sigma, mu] = local_fit(xtofit,ytofit,thr,dff);
yfit = A*exp(-(xi-mu).^2./(2*sigma^2));
if toplot
    figure; subplot(2,1,2);
    plot(xi,f);hold on;
%     plot(xtofit,yfit,'r-');
    subplot(2,1,1);
    plot(dff,'k-'); hold on
end

if toplot
    subplot(2,1,2)
    plot(xi,yfit,'r-');
end
%%%
dff = bsxfun(@minus,dff, mu);
if toplot
    subplot(2,1,1);
    plot(dff,'r-'); 
end


function [A,sigma, mu] = local_fit(x,y,thr,dff)

ymax = max(y);
xtrimmed = [];
ytrimmed = [];
%collect only those points which exceed given threshold- maxY*thr
for ix = 1:length(x)
    if y(ix)>ymax*thr;
        xtrimmed = [xtrimmed,x(ix)];
        ytrimmed = [ytrimmed,y(ix)];
    end
end
%put in log scale
ytrimmedlog = log(ytrimmed);
xtrimmedlog = xtrimmed;
%fit logged values with 2-nd order polynomial

P = polyfit(xtrimmedlog,ytrimmedlog,2);
%extract Gauss terms
sigma = sqrt(-1/(2*P(1)));
mu = P(2)*sigma^2;
A = exp(P(3)+mu^2/(2*sigma^2));

if isnan(A)
    disp('Doing linear interpolation');
    x2 = linspace(min(x), max(x));
    y2 = interp1(x,y,x2);
    x = x2; y = y2;
    xtrimmed = [];
    ytrimmed = [];
    for ix = 1:length(x)
        if y(ix) > ymax*thr;
            xtrimmed = [xtrimmed,x(ix)];
            ytrimmed = [ytrimmed,y(ix)];
        end
    end
    ytrimmedlog = log(ytrimmed);
    xtrimmedlog = xtrimmed;
end
P = polyfit(xtrimmedlog,ytrimmedlog,2);
%extract Gauss terms
sigma = sqrt(-1/(2*P(1)));
mu = P(2)*sigma^2;
A = exp(P(3)+mu^2/(2*sigma^2));

if ~isreal(sigma)
    dev = nanstd(dff);
    outliers = abs(dff)>2*dev;
    
    deltaF2 = dff;
    deltaF2(outliers) = NaN;
    sigma = nanstd(deltaF2);
    mu = nanmean(deltaF2);
    
end

