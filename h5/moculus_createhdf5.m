function out = moculus_createhdf5(hrfloc, hdf5loc, pars)
% out = moculus_createhdf5(hrfloc, hdf5loc, pars) - creates hdf5 file specified in
% hdf5loc, hrfloc - HUB root file location for that experiment.
% pars.stimtype - a string (eg. '8s_gray60Hz')
% pars.dffmethod - a string (e.g. 'median', 'mode', 'percentile')
% pars.tostitch - an integer {0 or 1}
% part of HELIOS
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
try
    fid = H5F.create(hdf5loc);
    plist = 'H5P_DEFAULT';
    gid = H5G.create(fid,'DATA',plist,plist,plist);
    H5G.close(gid);
    H5F.close(fid);
    h5writeatt(hdf5loc,'/DATA', 'ANIMALID', hrf.ID);
    h5writeatt(hdf5loc,'/DATA', 'SETUP', hrf.setup);
catch
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

for idl = 1:Ndata
    stageids{idl} = num2str(idl);
    behav_files{idl} = {hrf.measurements.session(idl).behavior_data.file_path};
end
disp('Storing data in hdf5 file. Please wait.')
tic
moculus_embeddata(hdf5loc, data_locations, stageids, behav_files);
t = toc;
disp(['Data stored in hdf5 file. Running time: ', num2str(t)]);

disp('Calculating df/f. Please wait.')
tic
ex = experiment(hdf5loc);
%dff [when no onacid]
ex = ex.dff(lower(method), tostitch, 1);
t = toc;
disp(['Df/f calculated and stored. Running time: ', num2str(t)]);

out = 1;