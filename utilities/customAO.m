function customAO(OB, d)
% customAO(file_location, d) - custom code by Gergely for
% light-contamination-based BG subtraction.
%part of HELIOS
Gsmooth = 10;  
file_location = OB.file_loc;
if nargin < 2
    d.BGcrit = 0.3;
    d.light_cont_scale = 0.7;
    d.perc = 0.08;
    d.BG_sub_scale = 0;
end

temp = h5info(file_location,'/ANALYSIS/');
Ncells = length(temp.Groups);
temp = h5info(file_location,'/ANALYSIS/ROI_1');
Nstages = length(temp.Groups);
setup = h5readatt(file_location,'/DATA','SETUP');
switch setup
    case 'ao'
        d.delay = 160;
    otherwise
        d.delay = 230;
end

for iroi = 1:Ncells
    for istage = 1:Nstages
        [d,X] = getstimparam(d,file_location,istage);
        for istim = 1:9
            loc = strcat('/ANALYSIS/ROI_',num2str(iroi),'/STAGE_',num2str(istage),'/STIM_',num2str(istim));
            units = h5readatt(file_location,loc,'UNITNUMBER');
            for irep = 1:length(units)
                loc = strcat('/DATA/STAGE_',num2str(istage),'/UNIT_',num2str(units(irep)),'/ROI_',num2str(iroi),'/YDATA');
                raw(irep,:) = h5read(file_location,loc);
            end
            for irep = 1:length(units)
                loc = strcat('/DATA/STAGE_',num2str(istage),'/UNIT_',num2str(units(irep)),'/ROI_',num2str(iroi),'/BG');
                bg(irep,:) = h5read(file_location,loc);
            end
            [bg_filt(:),passed(:)] = bgfilter(d,squeeze(bg(:,:)));                      
            [light_cont_with_bg(:),light_cont(:)] = light_contamination(d,squeeze(bg_filt(:)));
            bg_avg(:) = movmean(bg_filt(:) - d.light_cont_scale * light_cont(:), Gsmooth, 'omitnan');
            bg_baseline = prctile(bg_avg(:),d.perc);
            bg_dff(:) = bg_avg(:)/bg_baseline - 1;
            raw_dec(:,:) = squeeze(raw(:,:)) - squeeze(d.light_cont_scale * light_cont(:))'; 
            raw_dff(:,:) = visc_percentile_dff(X*1000,squeeze(raw_dec(:,:)), Gsmooth, 5, '');
            dff_new(:,:) = squeeze(raw_dff(:,:)) - d.BG_sub_scale * squeeze(bg_dff(:))';
            loc = strcat('/ANALYSIS/ROI_',num2str(iroi),'/STAGE_',num2str(istage),'/STIM_',num2str(istim),'/DFFBASE');%renamed DFF_CORR to DFFBASE
            try
                h5create(file_location,loc,size(dff_new),'ChunkSize',size(dff_new),'Deflate', 9);
            catch
            end
            h5write(file_location, loc, dff_new);
            clear raw bg bg_filt passed light_cont light_cont_with_bg bg_avg bg_baseline bg_dff dff_new raw_dec raw_dff units;
        end
    end         
end

function [BGfiltered_and_norm, passed] = bgfilter(d, bg)
    bgvar = nanvar(bg'); 
    Nreps = numel(bg(:,1));
    Nreps_to_use = ceil(Nreps*d.BGcrit);
    BGlimit = prctile(bgvar,d.BGcrit*1e2);
    passed = bgvar < BGlimit;
    BGfiltered_and_norm = nansum(passed'.*bg)./nansum(passed);


function [light_cont_with_bg_baseline, light_cont] = light_contamination(d, Y)
    bg_signal = prctile(Y(d.signal_int),d.perc);
    bg_baseline = prctile(Y(d.bl_int),d.perc);
    light_cont = zeros(1,length(Y));
    for i = d.stim_int
        light_cont(i) = bg_signal-bg_baseline;
        if light_cont(i)<0
            light_cont(i) = 0;
        end
    end
    light_cont_with_bg_baseline = light_cont+bg_baseline;


function [d, X] = getstimparam(d, file_location, istage)
    path = strcat('/DATA/STAGE_',num2str(istage),'/UNIT_1/XDATA');
    X = h5read(file_location,path).* 1e-3;
    path = strcat('/DATA/STAGE_',num2str(istage));
    stimtype = h5readatt(file_location,path,'STIMTYPE');
        stimstr = visc_recall_stims(stimtype);
        stim_start_time = stimstr.static1 + d.delay;
        stim_stop_time = stimstr.blank2 + d.delay;
        [~,stim_start_index] = min(abs(X-stim_start_time));
        [~,stim_stop_index] = min(abs(X-stim_stop_time));
    d.stim_int = stim_start_index:stim_stop_index;
        signal_start_time = stimstr.moving +500 + d.delay;           %signal time calculated when static and on transient ends
        signal_stop_time = stimstr.static2 -500 + d.delay;
        [~,signal_start_index] = min(abs(X-signal_start_time));
        [~,signal_stop_index] = min(abs(X-signal_stop_time));
    d.signal_int = signal_start_index:signal_stop_index;
        bl_start_time = stimstr.static1 -7500 + d.delay;              %basline time is before stim, same length as signal
        bl_stop_time = stimstr.static1 -500 + d.delay;
        [~,bl_start_index] = min(abs(X-bl_start_time));
        [~,bl_stop_index] = min(abs(X-bl_stop_time));
    d.bl_int = bl_start_index:bl_stop_index;
