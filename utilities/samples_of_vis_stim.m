function SAMP = samples_of_vis_stim(ob)
% SAMP = samples_of_vis_stim(ob) - collects sequential samples
% of a given time window twin from imaging time axis and groups them based
% on visual stimulus duration window

s = stimulus_protocol(ob.stim_type);%gives the stimulus landmarks in ms

% %s.blank1
% s.static1
% s.moving1
% s.static2
% s.blank2
% s.total
iroi = 1; %doesnt matter which ROI
Nstages = ob.N_stages;

range_in_mseconds = [s.static1,s.blank2];

for istage = 1:Nstages
    stim_order_v = export_stimulus_order(ob.restun{istage});
    unique_stimuli = unique(stim_order_v);
    unique_stimuli_cell = strsplit(num2str(unique_stimuli));
    st = ob.stitch(iroi, istage, 'raw');
    Nunits = (ob.N_stim(istage) * ob.N_reps(istage));
    Nsamples_per_unit = numel(st.time)./Nunits;
    time_one_unit = st.time(1:Nsamples_per_unit);
    one_unit_mask = time_one_unit >= range_in_mseconds(1) & time_one_unit <= range_in_mseconds(2);
    all_unit_mask = repmat(one_unit_mask, 1,Nunits);
    [~,idx] = find(all_unit_mask);
    SAMP.stage(istage).time_samples = idx;
    
    stim_order_idx = 1:Nunits;
    
    for istim = 1:numel(unique_stimuli_cell)
        cstim = str2num(unique_stimuli_cell{istim});
        cstim_idx = stim_order_idx(stim_order_v == cstim);
        samples = [];
        for iidx = 1:numel(cstim_idx)
            cidx = cstim_idx(iidx);
            current_unit_samples = [Nsamples_per_unit*(cidx-1)+1:Nsamples_per_unit*cidx];
            samples = [samples; current_unit_samples(one_unit_mask)];
        end
        SAMP.stage(istage).(['st_',unique_stimuli_cell{istim}]) = samples;
    end
%     for iunit = 1:Nunits
%         
%     end
end