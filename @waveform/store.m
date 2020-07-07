function store(W, exp, aoexception)
% store(W, exp, aoexception) - stores the waveform in the hdf5 file
%aoexception indicates whether it should store dff in unique DFFBASE path
if nargin < 3
    aoexception = 0;
end
for id = 1:numel(W.data(:,1))
    if strcmp(W.data_type, 'dff')
        if strcmp(W.tag{1,2},'DATA')
            stage_idx = find(contains(W.tag(id,:),'STAGE_'));
            stage_str = W.tag{id,stage_idx};
            stage_id = regexp(stage_str,'\d+(\.)?(\d+)?','match');
            stage_id = str2num(stage_id{:});
            roi_idx = find(contains(W.tag(id,:),'ROI_'));
            roi_str = W.tag{id,roi_idx};
            unit_idx = find(contains(W.tag(id,:),'UNIT_'));
            unit_str = W.tag{id,unit_idx};
            unit_id = regexp(unit_str,'\d+(\.)?(\d+)?','match');
            unit_id = str2num(unit_id{:});
            [istim, irep] = find(exp.restun{stage_id} == unit_id);
            data{istim}(irep,:) = W.data(id,:);
            if aoexception
                path{istim} = strjoin({'','ANALYSIS',roi_str, stage_str, ['STIM_',num2str(istim)],'DFFBASE'},'/');
            else
                path{istim} = strjoin({'','ANALYSIS',roi_str, stage_str, ['STIM_',num2str(istim)],upper(W.data_type)},'/');
            end
        elseif strcmp(W.tag{1,2},'ANALYSIS')
            data = {W.data};
            if aoexception
                path = {strjoin([W.tag,'DFFBASE'],'/')};%added 2020-07-01
            else
                path = {strjoin([W.tag,'DFF'],'/')};
            end
        else
            error('unknown path in tag');
        end
    elseif strcmp(W.data_type, {'bg'})
        data = W.data;
        for ip = 1:numel(W.tag(:,1))
            path{ip} = strjoin([W.tag(ip,:),'BG'],'/');
        end
    else
        error('this type of data cannot be stored');
    end
end
try
    allocatespace(exp.file_loc, data, path)
catch
end
storedata(exp.file_loc, data, path);