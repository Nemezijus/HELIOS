function out = moculus_createhdf5(hrfloc, hdf5loc, pars, MCpairs, stimlist)
% out = moculus_createhdf5(hrfloc, hdf5loc, pars, MCpairs, stimlist) - 
% creates hdf5 file specified in
% hdf5loc, hrfloc - HUB root file location for that experiment.
% pars.stimtype - a string (eg. '8s_gray60Hz')
% pars.dffmethod - a string (e.g. 'median', 'mode', 'percentile')
% pars.tostitch - an integer {0 or 1}
% part of HELIOS
if isempty(pars) || strcmp(pars.bgmethod,'skip')
    skipbg = 1;
else
    skipbg = 0;
end
%whether OnAcid
if strcmp(lower(pars.dffmethod),'onacid')
    do_onacid = 1;
    skipbg = 1; %onacid presence means no bg calculations [for now]8
else
    do_onacid = 0;
end
if do_onacid
    skipbg = 1;
end
if ~isstruct(hrfloc)
    S = load(hrfloc);
    Sfns = fieldnames(S);
    hrf = S.(Sfns{:});
else
    hrf = hrfloc;
end
if isempty(pars)
    method = 'median';
    tostitch = 1;
else
    method = pars.dffmethod;
    tostitch = pars.tostitch;
end

data_locations = {hrf.analysis.imaging.data.file_path};
if isempty(data_locations)
    disp('data.mat locations in hrf file not found');
    disp('attempting to index by sessions');
    data_locations = {};
    Ndata = numel([hrf.measurements.session]);
else
    Ndata = numel(data_locations);
end

try
    fid = H5F.create(hdf5loc);
    plist = 'H5P_DEFAULT';
    gid = H5G.create(fid,'DATA',plist,plist,plist);
    for idl = 1:Ndata
        gid2 = H5G.create(gid,['STAGE_',num2str(idl)],plist,plist,plist);
        H5G.close(gid2);
    end
    H5G.close(gid);
    H5F.close(fid);
    h5writeatt(hdf5loc,'/DATA', 'ANIMALID', hrf.ID);
    h5writeatt(hdf5loc,'/DATA', 'SETUP', hrf.setup);
catch
    disp('initial H5 creation failed!');
end



for idl = 1:Ndata
    stageids{idl} = num2str(idl);
    if ~isempty(hrf.measurements.session(idl).behavior_data)
        behav_files{idl} = {hrf.measurements.session(idl).behavior_data.file_path};
    else
        behav_files{idl} = [];
    end
end
if ~do_onacid
    disp('Storing data in hdf5 file. Please wait.')
    tic
    moculus_embeddata(hdf5loc, data_locations, stageids, behav_files);
    t = toc;
    disp(['Data stored in hdf5 file. Running time: ', num2str(t)]);
end

try
    for idl = 1:Ndata
        cloc = strjoin({'','DATA',['STAGE_',num2str(idl)]},'/');
        h5writeatt(hdf5loc,cloc,'STIMLIST',stimlist.order);
    end
catch
    disp('Stim list was not embedded');
end

for idl = 1:Ndata
    h5writeatt(hdf5loc,['/DATA/STAGE_',num2str(idl)], 'STIMTYPE', pars.stimtype);
end

for idl = 1:Ndata
    try
        if iscell(MCpairs(idl).motcorr)
            loc = MCpairs(idl).motcorr{:};
        else
            loc = MCpairs(idl).motcorr;
        end
        h5writeatt(hdf5loc,['/DATA/STAGE_',num2str(idl)], 'MOTIONCORRECTEDDATAPATH', loc);
    catch
        h5writeatt(hdf5loc,['/DATA/STAGE_',num2str(idl)], 'MOTIONCORRECTEDDATAPATH', []);
    end
end

if ~do_onacid
    for idl = 1:Ndata
        if iscell(MCpairs(idl).mescroi)
            loc = MCpairs(idl).mescroi{:};
        else
            loc = MCpairs(idl).mescroi;
        end
        h5writeatt(hdf5loc,['/DATA/STAGE_',num2str(idl)], 'MASKPATH', loc);
    end
else %TO BE CORRECTED
    locs = hrf.analysis.imaging.onacid.file_path(contains(hrf.analysis.imaging.onacid.file_path,'after'));
    for idl = 1:Ndata
        h5writeatt(hdf5loc,['/DATA/STAGE_',num2str(idl)], 'MASKPATH', locs{:});
    end
end

if ~do_onacid
    disp('Calculating df/f. Please wait.')
    tic
    ex = experiment(hdf5loc);
    %dff [when no onacid]
    ex = ex.dff(lower(method), tostitch, 1);
    t = toc;
    disp(['Df/f calculated and stored. Running time: ', num2str(t)]);
end


if ~skipbg
%     EXP = experiment(hdf5loc);
    ex = ex.extractbg(pars.bgmethod, hrf);%dynamic pixels is much much faster than staticpixels
    
    %subtract bg and estimate dff
    disp('Subtracting BG and calculating dff for the data. Please Wait.');
    tic
    ex = subtractbg(ex, pars);%if not skipping bg correction
    t = toc;
    disp(['DFF stored in hdf5 file. Running time: ', num2str(t)]);
    
    stitchstr = '';
    if tostitch
        stitchstr = '_stitched';
    end
    root = '/ANALYSIS';
    if strcmp(pars.bgcorrmethod, 'customao')
        h5writeatt(ex.file_loc,root,'DFFTYPE','percentile');
    else
        h5writeatt(ex.file_loc,root,'DFFTYPE',[lower(method), stitchstr]);
    end
    h5writeatt(ex.file_loc,root,'DFFMODDATE',datenum(now));
    h5writeatt(ex.file_loc,root,'DFFMODUSER',getenv('username'));
    
end
%%%HERE WE EMBED ONACID DATA
if do_onacid
    data_locations = {MCpairs.motcorr};
    onacidloc = MCpairs(1).onacid;
    onacidloc = strsplit(onacidloc{1},'\');
    onacidloc = onacidloc(1:end-1);
    onacidloc = strjoin(onacidloc,'\');
    out = moculus_embedonacid(hdf5loc, data_locations, onacidloc, stageids); 
end
%%%
h = waitbar(0,'Calculating Max Correlations');
for iroi = 1:ex.N_roi
    waitbar(iroi/ex.N_roi);
    C = ex.bestcorr(iroi);
    try
        allocatespace(ex.file_loc, {C}, {['/ANALYSIS/ROI_',num2str(iroi),'/MAXCORR']});
    catch
    end
    storedata(ex.file_loc, {C}, {['/ANALYSIS/ROI_',num2str(iroi),'/MAXCORR']});
end
close(h)

out = 1;