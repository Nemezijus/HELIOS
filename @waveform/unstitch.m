function uS = unstitch(S, ex)
% function uS = unstitch(S, ex) - unstitches the waveform in the stitched
% waveform S and places the traces back to their original rows in the data
% matrix. ex - experiment object.
% part of HELIOS
ncases = numel(S.tag);
unst_data = [];
unst_time = [];
tag = {};
visited = {};
for icase = 1:ncases
    ctags = S.tag{icase};
    all_unit_index = find(contains(ctags,'UNIT_'));
    all_stages_index = find(contains(ctags,'STAGE_'));
    stage_strings = ctags(all_stages_index);
    unit_strings = ctags(all_unit_index);
    numcells = regexp(unit_strings,'\d+(\.)?(\d+)?','match');
    units = str2double([numcells{:}])';
    Ts = 1./S.Fs(1)*1e-3;%sampling period
    unst_data = vertcat(unst_data,unstitchrows(S.data(icase,:), units, 'data', Ts, S.tag{icase}, ex.file_loc, visited));
    [u_time, visited] = unstitchrows(S.time(icase,:), units, 'time', Ts, S.tag{icase}, ex.file_loc, visited);
    unst_time = vertcat(unst_time,u_time);
    tag = [tag; ctags];
end
uS = waveform(unst_data, unst_time, S.data_type, S.time_units, S.data_units, tag);

function [st, visited] = unstitchrows(in, order, type, Ts, tag, fl, visited)
nelements = numel(in(1,:));
% st = zeros(1,prod(size(in)));
st = [];
switch type
    case 'data'
        start = 1;
        idorder = 1:numel(order);
        for io = 1:numel(order)
            ii = idorder(order==io);
            cio = order(io);
            datalen = numel(h5read(fl, [strjoin(tag(io,:),'/'),'/YDATA']));
            st(ii,:) = in(start:start+datalen-1);
            start = start+datalen;
        end
    case 'time'
        start = 1;
        counter = 1;
        for io = 1:numel(order)
            carray = tag(io,:);
            unit_index = find(contains(carray,'UNIT_'));
            stage_index = find(contains(carray,'STAGE_'));
            unit_string = carray{unit_index};
            stage_string = carray{stage_index};
            branches = strjoin({stage_string, unit_string},'/');
            datalen = numel(h5read(fl, [strjoin(tag(io,:),'/'),'/YDATA']));
            if ~ismember(branches, visited)
                st(counter,:) = in(start:start+datalen-1);
                visited{counter} = branches;
                counter = counter+1;
                
            end
        end
end