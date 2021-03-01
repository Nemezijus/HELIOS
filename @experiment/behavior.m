function B = behavior(ob)
% B = behavior(ob) - collects behavior data from the experiment and stores
% it in the behavior struct B
% ob - experiment object
% part of HELIOS

Nstages = ob.N_stages;
B.id = ob.id;

try
    protocol = h5readatt(ob.file_loc,'/DATA/STAGE_1/UNIT_1/BEHAVIOR','PROTOCOL');
catch
    msgbox('Behavior is not present in this experiment');
    B = [];
    return
end
B.protocol = protocol;

for istage = 1:Nstages
    B.stage(istage) = local_collect_in_stage(ob, istage, protocol);
end




function s = local_collect_in_stage(ob, istage, protocol)

units = ob.restun{istage};
Nunits = numel(units);

for iunit = 1:Nunits
    cunit = units(iunit);
    s.unit(iunit) = local_collect_in_unit(ob, istage, cunit, protocol);
end


function u = local_collect_in_unit(ob, istage, iunit, protocol)

u.time_offset = h5readatt(ob.file_loc,['/DATA/STAGE_',num2str(istage),...
    '/UNIT_',num2str(iunit),'/BEHAVIOR'],'TIME_OFFSET');

root = ['/DATA/STAGE_',num2str(istage),'/UNIT_',num2str(iunit),'/BEHAVIOR'];
locs = {'time','velocity','position','luminance'};
for iloc = 1:numel(locs)
    u.(locs{iloc}) = local_read_data(ob, root, locs{iloc});
end

croot = [root,'/EVENTS'];
locs = {'lick','lickdelta','licklock','teleport','trigger'};
for iloc = 1:numel(locs)
    u.events.(locs{iloc}) = local_read_data(ob, croot, locs{iloc});
end

croot = [root,'/PORTS'];
locs = {'port_a','port_b','port_c'};
for iloc = 1:numel(locs)
    u.ports.(locs{iloc}) = local_read_data(ob, croot, locs{iloc});
end

croot = [root,'/ZONES/CONTROL'];
switch protocol
    case 'moculus'
        locs = {'left','right'};
    case 'photostim'
        locs = {'aversive','right'};
end
for iloc = 1:numel(locs)
    u.zones.control.(locs{iloc}) = local_read_data(ob, croot, locs{iloc});
end

croot = [root,'/ZONES/DISCRIM'];
switch protocol
    case 'moculus'
        locs = {'aversive'};
    case 'photostim'
        locs = {'reward'};
end

for iloc = 1:numel(locs)
    u.zones.discrim.(locs{iloc}) = local_read_data(ob, croot, locs{iloc});
end

croot = [root,'/ZONES/NEUTRAL'];
locs = {'black','cloud'};
for iloc = 1:numel(locs)
    u.zones.neutral.(locs{iloc}) = local_read_data(ob, croot, locs{iloc});
end

function d = local_read_data(ob,root, loc)
try
    d = h5read(ob.file_loc, [root,'/',upper(loc)]);
catch
    d = NaN;
end