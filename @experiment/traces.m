function W = traces(OB,idxs,type)
% W = traces(OB,idxs) - extracts traces from experiment object OB, and
% stores them in waveform object W.
% idxs - 4 element cell specifying the following:
%
% {ROIID, STAGEID, STIMID, REPID, UNITID}. If one of them is indicated as 0, all
%
% instances of that group will be extracted. No more than one 0 is allowed.
%part of HELIOS


if nargin < 3
    type = 'raw'; %default is raw traces
end

[ROIID,STAGEID,STIMID,REPID,UNITID] = local_idx_parse(OB, idxs);

% if numel(idxs) < 4
%     REPID = 0;
% else
%     REPID = idxs(4);
% end
% if numel(idxs) < 3
%     STIMID = 0;
% else
%     STIMID = idxs(3);
% end
% if numel(idxs) < 2
%     STAGEID = 0;
% else
%     STAGEID = idxs(2);
% end
% ROIID = idxs(1);
% if ~iscell(ROIID)
%     ROIID = {ROIID(:)};
% end
% 
% if ~iscell(STAGEID)
%     STAGEID = {STAGEID(:)};
% end
% 
% if ~iscell(STIMID)
%     STIMID = {STIMID(:)};
% end
% 
% if ~iscell(REPID)
%     REPID = {REPID(:)};
% end

path_elements = OB.paths(strcmp({OB.paths{:,1}},'DATA'),:);
if isempty(UNITID)
    if REPID{:} == 0
        REPID = {1:OB.N_reps(STAGEID{:})};
    end
    if STIMID{:} == 0
        STIMID = {1:OB.N_stim(STAGEID{:})};
    end
end
%step 1 - time axis
if STAGEID{:} ~= 0
    if numel(idxs) < 5 || isempty(idxs{5}) || idxs{5} == 0
        idx = {NaN,STAGEID{:},OB.restun{STAGEID{:}}(STIMID{:}, REPID{:})};
    else
        idx = {NaN,STAGEID{:},idxs{5}};
    end
    %%added 2020-12-18
    if isempty(OB.restun{STAGEID{:}}(STIMID{:}, REPID{:}))%for no stim cases
        idx{end} = 1;
    end
    sz = size(path_elements);
    for irow = 1:sz(1)
        isbeh(irow) = 0;
        for icol = 1:numel(path_elements(irow,:))
            if strcmp('BEHAVIOR',path_elements{irow,icol})
                isbeh(irow) = 1;
            end
        end
    end
    if sum(isbeh) > 0
        idx = [idx,NaN];
    end
    %%till here
    P = makepaths(path_elements(~isbeh,:), idx);
else
end
clear isbeh

testloc = [P{1},'/XDATA'];
try
    h5read(OB.file_loc,testloc);
    is_old = 1;
    append1 = '/XDATA';
    append2 = '';
catch
    is_old = 0;
    append1 = '/IMAGING/XDATA';
    append2 = '/IMAGING';
end
for iP = 1:numel(P)
    loc = [P{iP},append1];
    time(iP,:) = h5read(OB.file_loc,loc);
    time_units{iP} = h5readatt(OB.file_loc,[P{iP}, append2],'TIMEUNITS');
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
            if is_old
                idx = {NaN,STAGEID{:},OB.restun{STAGEID{:}}(STIMID{:}, REPID{:}), ROIID{:}};
            else
                idx = {NaN,STAGEID{:},OB.restun{STAGEID{:}}(STIMID{:}, REPID{:}),NaN, ROIID{:}};
            end
            %%added 2020-12-18
            sz = size(path_elements);
            for irow = 1:sz(1)
                isbeh(irow) = 0;
                for icol = 1:numel(path_elements(irow,:))
                    if strcmp('BEHAVIOR',path_elements{irow,icol})
                        isbeh(irow) = 1;
                    end
                end
            end
            if sum(isbeh) > 0
                if sum(OB.N_stim) == 0
                    idx = {NaN, STAGEID{:}, OB.restun{STAGEID{:}}, NaN, ROIID{:}};
                end
            end
            %%till here
            P = makepaths(path_elements(~isbeh,:), idx);
        end
        for iP = 1:numel(P)
            data(iP,:) = h5read(OB.file_loc,[P{iP},'/YDATA']);
            tag(iP,:) = strsplit(P{iP},'/');
        end
        data_type = 'raw';
        data_units = 'a.u.';
    case {'bg', 'BG', '/BG'}
        if STAGEID{:} ~= 0
%             idx = {NaN,STAGEID{:},OB.restun{STAGEID{:}}(STIMID{:}, REPID{:}), ROIID{:}};
            if is_old
                idx = {NaN,STAGEID{:},OB.restun{STAGEID{:}}(STIMID{:}, REPID{:}), ROIID{:}};
            else
                idx = {NaN,STAGEID{:},OB.restun{STAGEID{:}}(STIMID{:}, REPID{:}),NaN, ROIID{:}};
            end
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
        
        if sum(strcmp({path_elements{:}},'UNIT_')) > 0
            idx = {NaN, ROIID{:}, STAGEID{:}, UNITID{:}};
            P = makepaths(path_elements, idx);
            data = [];
            stageid = STAGEID{:};
            for iP = 1:numel(P)
                cdata = h5read(OB.file_loc,[P{iP},'/DFF']);
                if sz(2) < sz(1)%a dirty fix. restore data in proper dimensions
                    cdata = cdata';
                end
                data = vertcat(data,cdata);
                tag(iP,:) = strsplit(P{iP},'/');
            end
        else
            
            if STAGEID{:} ~= 0
                idx = {NaN,ROIID{:},STAGEID{:}, STIMID{:}};
                P = makepaths(path_elements, idx);
            end
            data = [];
            stageid = STAGEID{:};
            stimid = STIMID{:};
            roiid = ROIID{:};
            REPS = local_real_repetitions(OB,stageid,stimid, roiid); %added 2020-11-04
            for iP = 1:numel(P)
                if numel(P) ~= numel(REPS)
                    error('mismatch!! investigate here');
                end
                cdata = h5read(OB.file_loc,[P{iP},'/DFF']);
                
                sz = size(cdata);
                if sz(2) < sz(1)%a dirty fix. restore data in proper dimensions
                    cdata = cdata';
                end
                %             cdata = cdata(REPID{:}, :);
                %             cdata = cdata(REPS{iP,:}, :);%modified 2020-11-04
                cdata = cdata(REPS{iP,:}(REPID{:}), :);%modified 2020-12-11
                data = vertcat(data,cdata);
                tag(iP,:) = strsplit(P{iP},'/');
            end
        end
        data_type = 'dff';
        data_units = '%';
end
W = waveform(data, time, data_type, time_units, data_units, tag);


function P = makepaths(pe, idx)
str = {'/'};
id = 1;

% newver = 0;
% for ipe = 1:numel(pe)
%     if strcmp('IMAGING',pe{ipe})
%         newver = 1;
%         idx = [idx, NaN];
%     end
% end
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
[e1,e2,e3,e4,e5] = deal('');
%works for 5 cases only for now
if numel(E) == 5
    [Dx,Cx,Bx,Ax,ax] = ndgrid(1:numel(E{1}),1:numel(E{2}),1:numel(E{3}),1:numel(E{4}),1:numel(E{5}));
elseif numel(E) == 4
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
            if numel(E) > 4
                e5 = E{5}(ax(:));
                if isrow(e5)
                    e5 = e5';
                end
            end
        end
    end
end
if numel(E) == 5
    P = strcat('/',e1,'/',e2,'/',e3,'/',e4,'/',e5);
elseif numel(E) == 4
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
P = P(~contains(P,'UNIT_0')); %added 2020 05 22 eliminates UNIT_0 (no recordings) entries

function REPS = local_real_repetitions(OB,stageid,stimid, roiid)
restun = OB.restun{stageid};

for istim = 1:numel(stimid)
    cs = stimid(istim);
    reps = restun(cs,:);
    repidx = 1:numel(reps);
    repidx = repidx(reps>0 & ~isnan(reps));
    REPS{istim,:} = repidx;
end
R = REPS{:};
%added 2021-02-24
for iroi = 1:numel(roiid)-1
    REPS{iroi+1,:} = R;
end

function [ROIID,STAGEID,STIMID,REPID,UNITID] = local_idx_parse(ob, idxs)
ROIID = idxs(1);
if ~iscell(ROIID)
    ROIID = {ROIID(:)};
end

if numel(idxs) < 2
    STAGEID = {0};
else
    STAGEID = idxs(2);
end
if ~iscell(STAGEID)
    STAGEID = {STAGEID(:)};
end

if STAGEID{:} == 0
    STAGEID = [1:ob.N_stages];
end




if ~any(ob.N_stim)
    REPID = {};
    STIMID = {};
    if numel(idxs) == 5 & ~((idxs{5}==0) | isempty(idxs{5}))%if UNIT ID is specified manually/by user
        for istage = 1:numel(STAGEID)
            if STAGEID{istage} ~= 0
                UNITID{istage} = idxs{5};
            end
        end
    else
        for istage = 1:numel(STAGEID)
            if STAGEID{istage} ~= 0
                UNITID{istage} = ob.restun{STAGEID{istage}};
            end
        end
    end
else
    if numel(idxs) < 4
        REPID = 0;
    else
        REPID = idxs(4);
    end
    if numel(idxs) < 3
        STIMID = 0;
    else
        STIMID = idxs(3);
    end
    
    if ~iscell(STIMID)
        STIMID = {STIMID(:)};
    end
    
    if ~iscell(REPID)
        REPID = {REPID(:)};
    end
    
    UNITID = {};
end
