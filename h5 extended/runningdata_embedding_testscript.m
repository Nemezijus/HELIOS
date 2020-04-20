function info = runningdata_embedding_testscript(hdfloc, mouseID)
% info = runningdata_embedding_testscript(hdfloc, mouseID) embedding
% during_imaging running data to the existing h5 file at hdfloc of
% referenced mouse by mouseID returnin the info of the updated file
% hdfloc -char- fullpath of hdf5
% mouseID -char- identifier of the animal (eg: '36C_1')

% hdf5 location 
floc = hdfloc;

% open hubroot file
[~, cM] = summonHUBroot(mouseID);

%runningdata2hdf5
[V, ROI] = runningdata2ROI(cM);
info = runningdata2hdf5(floc, V, ROI);