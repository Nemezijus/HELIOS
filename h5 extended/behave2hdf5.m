function behave2hdf5(fileloc, cS, isession, sessiondata)
% behave2hdf5(fileloc, cS, isession, sessiondata) updates existing file
% at location of floc with the data of training sessions 
% fileloc -char- a full path with file name and extension for the hdf5 storage
% cS -struct- currentStruct created by vrlog2struct_hg
% isession - integer- number of current session
% sessiondata -struct- stores info about trainng sessions


%STEP0 - create empty BEHAVE branch to store attribute
try
    fid = H5F.create(fileloc);
    
catch
    fid = H5F.open(fileloc);
end
try
    plist = 'H5P_DEFAULT';
    gid = H5G.create(fid,'BEHAVE',plist,plist,plist);
    H5G.close(gid);
catch
end
H5F.close(fid);
%STEP1 - store protocol type 
%(!) the str of this attribute should be an input var in the future, as it can vary per animal
try
    h5writeatt(fileloc, '/BEHAVE', 'BEHAVETYPE', 'aversive conditioning');
catch
end
%STEP2 - store session data
hdf5create(fileloc, cS, isession, sessiondata);


%steps
%1 - collect data
%2 - define dataloc, with dataname
%3 - summon createorwrite method
function hdf5create(fileloc, cS, isession, sessiondata)
% /BEHAVE level
dataroot = '/BEHAVE';

% /SESSION_# level
SESSIONstr = ['SESSION_',num2str(isession)];
loc = strjoin({dataroot, SESSIONstr},'/');    
flds = fields(cS);

% DATA
% /METADATA
% dataloc = strjoin({loc, 'METADATA'}, '/');
% if ~ismember('metadata', flds)
%     data = [];
% else
%     data = cS.metadata;
% end
% createorwrite(fileloc, dataloc, data, 'create');
% createorwrite(fileloc, dataloc, data, 'write');
% /HWTIME
if ismember('g_time', flds)
    data = cS.g_time;
    dataloc = strjoin({loc, 'HWTIME'}, '/');
    createorwrite(fileloc, dataloc, data, 'create');
    createorwrite(fileloc, dataloc, data, 'write');
end
% /INPUT1
if ismember('input_1', flds)
    data = cS.input_1;
    dataloc = strjoin({loc, 'INPUT1'}, '/');
    createorwrite(fileloc, dataloc, data, 'create');
    createorwrite(fileloc, dataloc, data, 'write');
end
% /PORTS (root)
root_port = strjoin({loc, 'PORTS'}, '/');
if ismember('output_1', flds)
    cS.port_A = cS.output_1;
    cS.port_B = cS.output_2;
    cS.port_C = cS.output_3;
end
flds = fields(cS);
% /PORTS/A
dataloc = strjoin({root_port, 'A'}, '/');
data = cS.port_A;
createorwrite(fileloc, dataloc, data, 'create');
createorwrite(fileloc, dataloc, data, 'write');
% /PORTS/B
dataloc = strjoin({root_port, 'B'}, '/');
data = cS.port_B;
createorwrite(fileloc, dataloc, data, 'create');
createorwrite(fileloc, dataloc, data, 'write');
% /PORTS/C
if ismember('port_C', flds)
    data = cS.port_C;
    dataloc = strjoin({root_port, 'C'}, '/');
    createorwrite(fileloc, dataloc, data, 'create');
    createorwrite(fileloc, dataloc, data, 'write');
end
% /XDATA (TIME)
dataloc = strjoin({loc, 'XDATA'}, '/');
data = cS.time;
createorwrite(fileloc, dataloc, data, 'create');
createorwrite(fileloc, dataloc, data, 'write');
% /YDATA (VELOCITY)
dataloc = strjoin({loc, 'YDATA'}, '/');
data = cS.velocity;
createorwrite(fileloc, dataloc, data, 'create');
createorwrite(fileloc, dataloc, data, 'write');
% /EVENTS (root)
root_events = strjoin({loc, 'EVENTS'}, '/');
% /EVENTS/TELEPORT
dataloc = strjoin({root_events, 'TELEPORT'}, '/');
data = cS.teleport;
createorwrite(fileloc, dataloc, data, 'create');
createorwrite(fileloc, dataloc, data, 'write');
% /EVENTS/PAUSE
if ismember('paused', flds)
    data = cS.paused;
    dataloc = strjoin({root_events, 'PAUSE'}, '/');
    createorwrite(fileloc, dataloc, data, 'create');
    createorwrite(fileloc, dataloc, data, 'write');
end
% /ZONES (root)
root_zones = strjoin({loc, 'ZONES'}, '/');
% /ZONES/NEUTRAL
if ismember('neutral', flds)
    data = cS.neutral;
    dataloc = strjoin({root_zones, 'NEUTRAL'}, '/');
    createorwrite(fileloc, dataloc, data, 'create');
    createorwrite(fileloc, dataloc, data, 'write');
end
% /ZONES/AVERSIVE
if ismember('aversive', flds)
    data = cS.aversive;
    dataloc = strjoin({root_zones, 'AVERSIVE'}, '/');
    createorwrite(fileloc, dataloc, data, 'create');
    createorwrite(fileloc, dataloc, data, 'write');
end
% /ZONES/LEFT
if ismember('left', flds)
    data = cS.left;
    dataloc = strjoin({root_zones, 'LEFT'}, '/');
    createorwrite(fileloc, dataloc, data, 'create');
    createorwrite(fileloc, dataloc, data, 'write');
end
% /ZONES/RIGHT
if ismember('right', flds)
    data = cS.right;
    dataloc = strjoin({root_zones, 'RIGHT'}, '/');
    createorwrite(fileloc, dataloc, data, 'create');
    createorwrite(fileloc, dataloc, data, 'write');
end
% /ZONES/REWARD
if ismember('rewarding', flds)
    data = cS.rewarding;
    dataloc = strjoin({root_zones, 'REWARD'}, '/');
    createorwrite(fileloc, dataloc, data, 'create');
    createorwrite(fileloc, dataloc, data, 'write');
end

% ATTRIBUTES
% /TRAININGTYPE
str = sessiondata(isession).stage_name;
h5writeatt(fileloc, loc, 'TRAININGTYPE', str);
% /TRAININGDATE --> DATE && TIME
str = sessiondata(isession).file_name(1:16);
h5writeatt(fileloc, loc, 'TRAININGDATE', str);
% /TRAINERID
str = sessiondata(isession).trainer_name;
h5writeatt(fileloc, loc, 'TRAINERID', str);
% /SW --> GOOD QUESTION
str = sessiondata(isession).sw;
h5writeatt(fileloc, loc, 'SW', str);
% /HW
str = sessiondata(isession).hw;
h5writeatt(fileloc, loc, 'HW', str);
% /FS
if ismember('fs', flds)
    intgr = cS.fs;
    h5writeatt(fileloc, loc, 'FS', intgr);
end


function createorwrite(fileloc, loc, data, flag)
if strcmp(flag,'create')
    create = 1;
else
    create = 0;
end
if create
    try
        h5create(fileloc,loc,size(data),'ChunkSize',size(data),'Deflate',9);
    catch
    end
else
    h5write(fileloc,loc,data);
end