function out = moculus_createhdf5(hrfloc, hdf5loc, pars)
% out = moculus_createhdf5(hrfloc, hdf5loc, pars) - creates hdf5 file specified in
% hdf5loc, hrfloc - HUB root file location for that experiment.
% pars.stimtype - a string (eg. '8s_gray60Hz')
% pars.dffmethod - a string (e.g. 'median', 'mode', 'percentile')
% pars.tostitch - an integer {0 or 1}
% part of HELIOS

S = load(hrfloc);
Sfns = fieldnames(S);
hrf = S.(Sfns{:});


fid = H5F.create(hdf5loc);
plist = 'H5P_DEFAULT';
gid = H5G.create(fid,'DATA',plist,plist,plist);
H5G.close(gid);
H5F.close(fid);
h5writeatt(hdf5loc,'/DATA', 'ANIMALID', hrf.ID);
h5writeatt(hdf5loc,'/DATA', 'SETUP', hrf.setup);



data_locations = {hrf.analysis.imaging.data.file_path};
for idl = 1:numel(data_locations);
    stageids{idl} = num2str(idl);
    behav_files{idl} = {hrf.measurements.session(idl).behavior_data.file_path};
end
disp('Storing data in hdf5 file. Please wait.')
tic
moculus_embeddata(hdf5loc, data_locations, stageids, behav_files);
t = toc;
disp(['Data stored in hdf5 file. Running time: ', num2str(t)]);
out = 1;
% datapaths{1} = 'N:\DATA\pinke.domonkos\2020\Moculus_Analyised\_620mc\Day1\Standard\data.mat';
% datapaths{2} = 'N:\DATA\pinke.domonkos\2020\Moculus_Analyised\_620mc\Day2\data.mat';
% datapaths{3} = 'N:\DATA\pinke.domonkos\2020\Moculus_Analyised\_620mc\Day3\standard\data.mat';
% 
% behavior_files{1} = {'N:\DATA\pinke.domonkos\2020\Moculus_Analyised\_620mc\Day1\Standard\',...
%     'N:\DATA\pinke.domonkos\2020\Moculus_Analyised\_620mc\Day1\Standard\',...
%     'N:\DATA\pinke.domonkos\2020\Moculus_Analyised\_620mc\Day1\Standard\',...
%     'N:\DATA\pinke.domonkos\2020\Moculus_Analyised\_620mc\Day1\Standard\'}
% behavior_files{2} = {'','','','',''}
% behavior_files{3} = {'','','','',''}