function out = createhdf5(hrfloc, hdf5loc, pars)
% out = createhdf5(hrfloc, hdf5loc, pars) - creates hdf5 file specified in
% hdf5loc, hrfloc - HUB root file location for that experiment.
% pars.stimtype - a string (eg. '8s_gray60Hz')
% pars.dffmethod - a string (e.g. 'median', 'mode', 'percentile')
% pars.tostitch - an integer {0 or 1}
% part of HELIOS
if nargin < 3
    pars = [];
end
skipbg = 1;
S = load(hrfloc);
Sfns = fieldnames(S);
hrf = S.(Sfns{:});

ID = hrf.ID;
setup = hrf.setup;

if isempty(pars)
    if strcmp(setup,'ao')
        if str2num(ID(1:2)) > 36
            pars.stimtype = '13.5s_gray60Hz';
        else
            pars.stimtype = '14s_gray60Hz';
        end
    else
        pars.stimtype = '8s_gray60Hz';
    end
    pars.dffmethod = 'median';
    pars.tostitch = 1;
end

%STEP 1 - create empty DATA branch to store ID and setup
fid = H5F.create(hdf5loc);
plist = 'H5P_DEFAULT';
gid = H5G.create(fid,'DATA',plist,plist,plist);
H5G.close(gid);
H5F.close(fid);

%STEP 2 store ID and setup
h5writeatt(hdf5loc,'/DATA', 'ANIMALID', ID);
h5writeatt(hdf5loc,'/DATA', 'SETUP', setup);


%STEP 3 store data
data_locations = hrf.analysis.imaging.data_matrices.file_path;
for idl = 1:numel(data_locations)
    segments = strsplit(data_locations{idl},'\');
    idsegment = segments{end-1};
    stageids{idl} = upper([idsegment(1),idsegment(end)]);
end
disp('Storing data in hdf5 file. Please wait.')
tic
embeddata(hdf5loc, data_locations, stageids);
t = toc;
disp(['Data stored in hdf5 file. Running time: ', num2str(t)]);

%STEP 4 store stimtype
for idl = 1:numel(data_locations)
    h5writeatt(hdf5loc,['/DATA/STAGE_',num2str(idl)], 'STIMTYPE', pars.stimtype);
end

%STEP 5 pull out experiment from the file
EXP = experiment(hdf5loc);


%STEP 6 adding dff method
if isempty(pars)
    method = 'median';
    tostitch = 1;
else
    method = pars.dffmethod;
    tostitch = pars.tostitch;
end

disp('Calculating dff for the data. Please Wait.');
tic
EXP = EXP.dff(method, tostitch);
t = toc;
disp(['DFF stored in hdf5 file. Running time: ', num2str(t)]);

%STEP 7 add data, motion corrected file and roi mask file locations
locs = extractlocations(hrf.imaging, 'data');
for idl = 1:numel(data_locations)
    h5writeatt(hdf5loc,['/DATA/STAGE_',num2str(idl)], 'DATAPATH', locs{idl});
end

locs = extractlocations(hrf.imaging, 'motion_corrected_data');
for idl = 1:numel(data_locations)
    h5writeatt(hdf5loc,['/DATA/STAGE_',num2str(idl)], 'MOTIONCORRECTEDDATAPATH', locs{idl});
end

locs = extractlocations(hrf.imaging, 'roi');
for idl = 1:numel(data_locations)
    h5writeatt(hdf5loc,['/DATA/STAGE_',num2str(idl)], 'MASKPATH', locs{idl});
end

%STEP 8 BG extraction
if ~skipbg
    EXP = experiment(hdf5loc);
    EXP = EXP.extractbg('dynamicpixels');%dynamic pixels is much much faster than staticpixels
end

%STEP 9 add ROIBOX
% N = 5;
% for istage = 1:EXP.N_stages
%     for iroi = 1:EXP.N_roi
%         mask = h5read(EXP.file_loc,['/ANALYSIS/ROI_',num2str(iroi),'/STAGE_',num2str(istage),'/ROIMASK']);
%         R = roi(mask,N);
%         img = h5read(EXP.file_loc, ['/DATA/STAGE]);
%     end
% end
out = 1;



function locs = extractlocations(root, type)
fns = fieldnames(root);
count = 1;
for ifn = 1:numel(fns)
    cfn = fns{ifn};
    for ielem = 1:numel(root.(cfn))
        try
            locs{count} = root.(cfn)(ielem).(type).file_path;
            count = count+1;
        catch
        end
    end
end
