function SAMP = samples_of_teleported_to(ob, twin)
% SAMP = samples_of_teleported_to(ob, twin) - collects sequential samples
% of a given time window twin from imaging time axis and groups them based
% on which zone did the teleport happen to

S_tel = sample_matching(ob,'teleport');
S_rew = sample_matching(ob,'reward');
S_clo = sample_matching(ob,'cloud');
S_ave = sample_matching(ob,'aversive');
jump_zones = {};
roiid = 1;%does not matter which roi
Nst = ob.N_stages;
for ist = 1:Nst
    units = ob.restun{ist};
    for unit = units
        c_trace = ob.traces({roiid, ist, [], [], unit},'dff');
        dff_time = c_trace.time;
        switch c_trace.time_units %force to be in seconds
            case 'us'
                dff_time = dff_time .* 1e-6;
            case 'ms'
                dff_time = dff_time .* 1e-3;
            case 's'
                dff_time = dff_time;
            otherwise
                error('unknown time units')
        end
        twin_samples = sum(dff_time <= twin);%how many samples correspond twin
        s_tel = unique(S_tel.stage(ist).unit(unit).idx);
        s_rew = unique(S_rew.stage(ist).unit(unit).idx);
        s_clo = unique(S_clo.stage(ist).unit(unit).idx);
        s_ave = unique(S_ave.stage(ist).unit(unit).idx);
        counter = 1;
        for itel = s_tel
            zone{counter} = next_sample_membership(itel+1, s_rew, s_clo, s_ave);
            SAMP.stage(ist).unit(unit).samples(counter,:) = itel:itel+twin_samples-1;
            counter = counter+1;
        end
        un_zones = unique(zone);
        for iz = 1:numel(un_zones)
            if ~ismember(un_zones{iz}, jump_zones)
                jump_zones{numel(jump_zones)+1} = un_zones{iz};
            end
        end
        SAMP.stage(ist).unit(unit).zones_to = zone;
        clear zone
    end
end
for ist = 1:Nst
    units = ob.restun{ist};
    for unit = units
        for ijz = 1:numel(jump_zones)
            SAMP.stage(ist).unit(unit).(jump_zones{ijz}) = ...
                SAMP.stage(ist).unit(unit).samples(ismember(SAMP.stage(ist).unit(unit).zones_to,jump_zones{ijz}),:);
        end
    end
end

function z = next_sample_membership(idx, rew, clo, ave)
idx = [idx+1:idx+3]; %next samples
[isclo,isrew,isave] = deal(0);
if sum(ismember(idx, rew)) > 0
    isrew = 1;
end
if sum(ismember(idx, clo)) > 0
    isclo = 1;
end
if sum(ismember(idx, ave)) > 0
    isave = 1;
end

condisum = sum([isrew, isclo, isave]);

if condisum < 1
    disp('next sample is not part of any given zones!')
    z = '';
    return
end
if condisum > 1
    disp('next sample somehow belongs to multiple zones')
    z = '';
    return
end

if isrew
    z = 'reward';
end

if isclo
    z = 'clouds';
end

if isave
    z = 'aversive';
end