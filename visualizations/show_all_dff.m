function show_all_dff(exp, iroi, istage, istim, irep)
% show_all_dff(exp, iroi, istage, istim, irep) - visualizes all dff methods
% for a given experiment object exp. 
% iroi, istage, istim, irep  - indices of respective conditions
% part of HELIOS

if nargin <5
    irep = 0;
end
if nargin < 4
    istim = 0;
end
if nargin < 3
    istage = 0;
end
if nargin < 2
    iroi = 0;
end
allstim = 0;
allreps = 0;
if istim == 0 & irep ~=0
    allstim = 1;
end
if istim ~= 0 & irep== 0
    allreps = 1;
end
if allstim & allreps
    error ('too many traces are requested to be plotted');
end

if istage ~=0
    Nstages = numel(istage);
else
    Nstages = exp.N_stages;
    istage = 1:Nstages;
end

if istim~=0
    Nstim = numel(istim);
else
    Nstim = exp.N_stim;
    istim = 1:Nstim(1);%?
end

if irep ~= 0
    Nreps = numel(irep);
else
    Nreps = exp.N_reps(istim);
    irep = 1:Nreps(1);%?
end

if iroi ~= 0
    Nroi = numel(iroi);
else
    Nroi = exp.N_roi;
    iroi = 1:Nroi;
end

F = figure;
set(F,'units', 'normalized', 'position', [0.18 0.0833 0.53 0.813],'Color','white');
AX = autoaxes(F, 3, 2, [0.05 0.05 0.05 0.05],[0.05 0.05]);
dpars = dffparams(exp);
cols = local_colors;
for istg = 1:Nstages
    cstage = istage(istg);
    linew = istg;
    for ir = 1:Nroi
        croi = iroi(ir);
        St = stitch(exp, croi, cstage,'raw');
        rsutable = exp.restun{istage};
        for istm = 1:Nstim
            cstim = istim(istm);
            for irp = 1:Nreps
                if allreps
                    currcolor = cols(irp,:);
                else
                    currcolor = cols(istm,:);
                end
                crep = irep(irp);
                W = traces(exp, {croi,cstage,cstim,crep},'raw');
                hold on
                %1 - raw data
                axes(AX(1,1));
                W.plot([],currcolor); hold on
                title('raw');
                box on
                %2 - mean dff
                [single_mean(irp,:), stitched_mean(irp,:)] = local_plot(W, AX(2,1), 'mean', dpars, St, exp, cstim, crep, currcolor,linew, rsutable);
                title('Mean');
                %3 - gauss dff
                [single_gauss(irp,:), stitched_gauss(irp,:)] = local_plot(W, AX(3,1), 'gauss', dpars, St, exp, cstim, crep, currcolor,linew, rsutable);
                title('Gauss');
                %4 - percentile dff
                [single_percentile(irp,:), stitched_percentile(irp,:)] = local_plot(W, AX(1,2), 'percentile', dpars, St, exp, cstim, crep, currcolor,linew, rsutable);
                title('Percentile');
                %5 - mode dff
                [single_mode(irp,:), stitched_mode(irp,:)] = local_plot(W, AX(2,2), 'mode', dpars, St, exp, cstim, crep, currcolor,linew, rsutable);
                title('Mode');
                %6 - median dff
                [single_median(irp,:), stitched_median(irp,:)] = local_plot(W, AX(3,2), 'median', dpars, St, exp, cstim, crep, currcolor,linew, rsutable);
                title('Median');
            end
            if  Nreps == exp.N_reps;
                axes(AX(2,1));
                plot(W.time, mean(single_mean), 'k-','linew',2);hold on
                plot(W.time, mean(stitched_mean), '-','Color',[0.6 0.6 0.6],'linew',2);
                axes(AX(3,1));
                plot(W.time, mean(single_gauss), 'k-','linew',2);hold on
                plot(W.time, mean(stitched_gauss), '-','Color',[0.6 0.6 0.6],'linew',2);
                axes(AX(1,2));
                plot(W.time, mean(single_percentile), 'k-','linew',2);hold on
                plot(W.time, mean(stitched_percentile), '-','Color',[0.6 0.6 0.6],'linew',2);
                axes(AX(2,2));
                plot(W.time, mean(single_mode), 'k-','linew',2);hold on
                plot(W.time, mean(stitched_mode), '-','Color',[0.6 0.6 0.6],'linew',2);
                axes(AX(3,2));
                plot(W.time, mean(single_median), 'k-','linew',2);hold on
                plot(W.time, mean(stitched_median), '-','Color',[0.6 0.6 0.6],'linew',2);
            end
        end
    end
end
ch = get(gcf, 'children');
set(ch, 'box','on');

function [out1, out2] = local_plot(W, ax, type, dpars, St, exp, cstim, crep, col, linew, rsutable)
Wdff = W.dff(type,dpars);
Wdff.plot(ax,col); hold on
Wdffst = St.dff(type,dpars);
uS = unstitch(Wdffst, exp);
id = rsutable(cstim, crep);
id = find(rsutable == id);
axes(ax);
hold on
plot(uS.time(id,:), uS.data(id,:),'color',col,'linest',':','linewidth',linew);
out1 = Wdff.data;
out2 = uS.data(id,:);
a=1;
function cols = local_colors
cols = [0.8941    0.1020    0.1098;
    0.2157    0.4941    0.7216;
    0.3020    0.6863    0.2902;
    0.5961    0.3059    0.6392;
    1.0000    0.4980         0;
    1.0000    1.0000    0.2000;
    0.6510    0.3373    0.1569;
    0.9686    0.5059    0.7490;
    0.6000    0.6000    0.6000
    0.7451    0.6824    0.8314;
    0.9922    0.7529    0.5255;
    1.0000    1.0000    0.6000];