function S = sample_matching(ob,behave_event)
% S = sample_matching(ob,behave_event) - finds the sample equivalent in
% df/f time axis for a behavior event.
% sample matching finds the counterpart sample indices for the specified
% behavior event in the time axis of the df/f. For example in case of
% 'teleport', it first finds which ssamples in teleport vector are
% non-zero, remaps these samples to the time axis in 'waveform' object and
% returns those samples back.

if nargin < 2
    behave_event = 'teleport';
end
Nst = ob.N_stages;
B = ob.behavior;
if isempty(B)
    msgbox('no behavior data! Terminating');
    return
end
roiid = 1; %does not matter for which ROI

if sum(ob.N_stim) ~= 0
    msgbox('visual stimulus protocol present. This method is not applicable here');
    return
end

for ist = 1:Nst
    units = ob.restun{ist};
    cB = B.stage(ist);
    for unit = units
        cBu = cB.unit(unit);
        c_trace = ob.traces({roiid, ist, [], [], unit},'dff');
        s = local_matching(cBu,c_trace,behave_event);
        S(ist).unit(unit).sample_idx = s;
    end
end

function s = local_matching(b,t,flag)

offset = b.time_offset;
beh_time = b.time';%should be in seconds by default
beh_data = b.events.(flag)';%this needs to be made more flexible!!!

dff_time = t.time;
switch t.time_units %force to be in seconds
    case 'us'
        dff_time = dff_time .* 1e-6;
    case 'ms'
        dff_time = dff_time .* 1e-3;
    case 's'
        dff_time = dff_time;
    otherwise
        error('unknown time units')
end
%here we trim behavior sequences to match time window of df/f data
mask = beh_time>= offset & beh_time <= dff_time(end)+offset;

beh_time_cut = beh_time(mask);
beh_time_cut = beh_time_cut - beh_time_cut(1);
beh_data_cut = beh_data(mask);

beh_samples = 1:numel(beh_time_cut);
beh_match_time = beh_time_cut(beh_data_cut>0);
disp(['Number of point of interest: ',num2str(numel(beh_match_time))]);
beh_match_samples = beh_samples(beh_data_cut>0);%might not be needed

for ibm = 1:numel(beh_match_time)
    [~,dff_time_match_idx(ibm)] = min(abs(dff_time - beh_match_time(ibm)));
end
dff_time_match = dff_time(dff_time_match_idx);
disp(['behavior and dff samples matched. Mean absolute time error is: ', ...
    num2str(mean(abs(beh_match_time - dff_time_match)))])
s = dff_time_match_idx;