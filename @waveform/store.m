function store(W, exp)
% store(W, exp) - stores the waveform in the hdf5 file
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
            path{istim} = strjoin({'','ANALYSIS',roi_str, stage_str, ['STIM_',num2str(istim)],upper(W.data_type)},'/');
        elseif strcmp(W.tag{1,2},'ANALYSIS')
            data = {W.data};
            path = {strjoin([W.tag,'DFF'],'/')};
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