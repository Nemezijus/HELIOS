function info = runningdata2hdf5(fileloc, V, ROI)
% info = runningdata2hdf5(fileloc, V) - regroups data from V(elocity, during imaging)
% structs to a single hdf5 file format. 
% fileloc -char- a full path with file name and extension for the hdf5 storage
% V -struct- containing all relevant during velocity running data

hdf5create(fileloc, V,  ROI);
hdf5attrwrite(fileloc);

info = h5info(fileloc);

function hdf5create(fileloc, V,  ROI)
NSTAGES = numel(ROI(1).STAGE);
MN = visc_remap_measurenumber(ROI);
dataroot = '/DATA';
% /STAGE_# level
for istage = 1:NSTAGES
    STAGEstr = ['STAGE_',num2str(istage)];
    NUNITS = numel(MN.STAGE(istage).mn);
    for iunit = 1:NUNITS
        % /UNIT_# level
        UNITstr = ['UNIT_',num2str(iunit)];
        logv = MN.STAGE(istage).mn == iunit;
        istim = MN.STAGE(istage).stim(logv);
        loc = strjoin({dataroot,STAGEstr,UNITstr},'/');
        % /RUNNINGDATA
        ref_time = ROI(1).STAGE(istage).STIM(istim).Xdata;
        if isempty(V(istage).running_data)
            data = NaN(1, length(ref_time));
        else
            V(istage).running_data(iunit).time = linspace(ref_time(1), ref_time(end), length(V(istage).running_data(iunit).time));
            if ~isnan(V(istage).running_data(iunit).vel)
                data = interp1(V(istage).running_data(iunit).time, V(istage).running_data(iunit).vel, ref_time);
            else
                data = NaN(1, length(ref_time));
            end
        end
        dataloc = strjoin({loc,'RUNNINGDATA'},'/');
        createorwrite(fileloc, dataloc, data, 'create');
        createorwrite(fileloc, dataloc, data, 'write');
    end
end


function hdf5attrwrite(fileloc)
dataroot = '/DATA';
h5writeatt(fileloc, dataroot, 'BEHAVSETUP', 'gramophone');


function createorwrite(fileloc, loc, data, flag)
if strcmp(flag ,'create')
    create = 1;
else
    create = 0;
end
if create
    try
        h5create(fileloc,loc,size(data),'ChunkSize',size(data), 'Deflate', 9);
    catch
    end
else
    h5write(fileloc,loc,data);
end