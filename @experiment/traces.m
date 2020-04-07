function W = traces(OB,idxs,type)
% W = traces(OB,idxs) - extracts traces from experiment object OB, and
% stores them in waveform object W.
% idxs - 4 element cell specifying the following:
%
% {ROIID, STAGEID, STIMID, REPID}. If one of them is indicated as 0, all
%
% instances of that group will be extracted. No more than one 0 is allowed.
%part of HELIOS

if nargin < 3
    type = 'raw'; %default is raw traces
end

if numel(idxs) < 4
    REPID = 0;
end
if numel(idxs) < 3
    STIMID = 0;
end
if numel(idxs) < 2
    STAGEID = 0;
end
ROIID = idxs(1);
if ~iscell(ROIID)
    ROIID = {ROIID(:)};
end
STAGEID = idxs(2);
if ~iscell(STAGEID)
    STAGEID = {STAGEID(:)};
end
STIMID = idxs(3);
if ~iscell(STIMID)
    STIMID = {STIMID(:)};
end
REPID = idxs(4);
if ~iscell(REPID)
    REPID = {REPID(:)};
end

path_elements = OB.paths(strcmp({OB.paths{:,1}},'DATA'),:);
if REPID{:} == 0
    REPID = {1:OB.N_reps(STAGEID{:})};
end
if STIMID{:} == 0
    STIMID = {1:OB.N_stim(STAGEID{:})};
end
%step 1 - time axis
if STAGEID{:} ~= 0
    idx = {NaN,STAGEID{:},OB.restun{STAGEID{:}}(STIMID{:}, REPID{:})};
    P = makepaths(path_elements, idx);
else
end
for iP = 1:numel(P)
    loc = [P{iP},'/XDATA'];
    time(iP,:) = h5read(OB.file_loc,loc);
    time_units{iP} = h5readatt(OB.file_loc,P{iP},'TIMEUNITS');
end

if sum(strcmp(time_units,time_units{1})) == numel(time_units)
    time_units = time_units{1};
else
    error('time units are not matching');
end
%step 2 - data axis
%depending on specified type, assigns different kind of waveforms to data
%field of the waveform object.
switch type
    case {'raw', 'YDATA', '/YDATA'}
        if STAGEID{:} ~= 0
            idx = {NaN,STAGEID{:},OB.restun{STAGEID{:}}(STIMID{:}, REPID{:}), ROIID{:}};
            P = makepaths(path_elements, idx);
        end
        for iP = 1:numel(P)
            data(iP,:) = h5read(OB.file_loc,[P{iP},'/YDATA']);
            tag(iP,:) = strsplit(P{iP},'/');
        end
        data_type = 'raw';
        data_units = 'a.u.';
    case {'bg', 'BG', '/BG'}
        if STAGEID{:} ~= 0
            idx = {NaN,STAGEID{:},OB.restun{STAGEID{:}}(STIMID{:}, REPID{:}), ROIID{:}};
            P = makepaths(path_elements, idx);
        end
        for iP = 1:numel(P)
            data(iP,:) = h5read(OB.file_loc,[P{iP},'/BG']);
            tag(iP,:) = strsplit(P{iP},'/');
        end
        data_type = 'bg';
        data_units = 'a.u.';
    case {'dff', 'DFF', '/DFF'}
        path_elements = OB.paths(strcmp({OB.paths{:,1}},'ANALYSIS'),:);
        if STAGEID{:} ~= 0
            idx = {NaN,ROIID{:},STAGEID{:}, STIMID{:}};
            P = makepaths(path_elements, idx);
        end
        data = [];
        for iP = 1:numel(P)
            cdata = h5read(OB.file_loc,[P{iP},'/DFF']);
            cdata = cdata(REPID{:}, :);
            data = vertcat(data,cdata);
            tag(iP,:) = strsplit(P{iP},'/');
        end
        data_type = 'dff';
        data_units = '%';
end
W = waveform(data, time, data_type, time_units, data_units, tag);


function P = makepaths(pe, idx)
str = {'/'};
id = 1;
while id <= numel(idx)
    for ii = 1:numel(idx{id})
        if ~isnan(idx{id}(ii))
            substr{ii} = [pe{id},num2str(idx{id}(ii))];
        else
            substr{ii} = pe{id};
        end
    end
    E{id} = substr;
    id = id+1;
    clear substr
end
N = prod(cellfun(@numel, E));
[e1,e2,e3,e4] = deal('');
%works for 4 cases only for now
if numel(E) == 4
    [Dx,Cx,Bx,Ax] = ndgrid(1:numel(E{1}),1:numel(E{2}),1:numel(E{3}),1:numel(E{4}));
elseif numel(E) == 3
    [Dx,Cx,Bx] = ndgrid(1:numel(E{1}),1:numel(E{2}),1:numel(E{3}));
elseif numel(E) == 2
    [Dx,Cx] = ndgrid(1:numel(E{1}),1:numel(E{2}));
elseif numel(E) == 1
    [Dx] = ndgrid(1:numel(E{1}));
else
    error('for some reason the path is empty');
end
e1 = E{1}(Dx(:));
if isrow(e1)
    e1 = e1';
end
if numel(E) > 1
    e2 = E{2}(Cx(:));
    if isrow(e2)
        e2 = e2';
    end
    if numel(E) > 2
        e3 = E{3}(Bx(:));
        if isrow(e3)
            e3 = e3';
        end
        if numel(E) > 3
            e4 = E{4}(Ax(:));
            if isrow(e4)
                e4 = e4';
            end
        end
    end
end
if numel(E) == 4
    P = strcat('/',e1,'/',e2,'/',e3,'/',e4);
elseif numel(E) == 3
    P = strcat('/',e1,'/',e2,'/',e3);
elseif numel(E) == 2
    P = strcat('/',e1,'/',e2);
elseif numel(E) == 1
    P = strcat('/',e1);
else
    error('for some reason the path is empty');
end

