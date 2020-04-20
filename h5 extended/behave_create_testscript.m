function info = behave_create_testscript(hdfloc, mouseID)
% info = behave_create_testscript(hdfloc, mouseID) is a test script which
% runs the behave2hdf5 method to generate a BEHAVE branch in the existind
% hdf5 file of referenced (mouseID) animal
% inputs
% hdfloc -char- location of the h5 file of the animal
% mouseID -char- identifier of the animal (eg: '36C_1')
% output
% info -struct- stores information about updated hd file

% hdf5 location 
floc = hdfloc;

% open hubroot file
% now
[~, cM] = summonHUBroot(mouseID);
% future
% fighub = findobj('Tag', 'HUB');
% hubdata = guidata(fighub);

% creating a struct called sessiondata containing all the informations
% about training sessions
flds = fields(cM.behavior);
counter = 1;
for istages=1:numel(flds)
try
 if ~isempty(cM.behavior.(flds{istages})(1).data.directory_path{1})
    if any(ismember(cM.behavior.(flds{istages})(1).data.tag, 'during_imaging'))
        continue
    else
     cpath = cM.behavior.(flds{istages})(1).data.directory_path{1};
    end
 end
catch
    disp(['Behavior directory path of ', flds{istages}, ' is empty!']);
    continue
end
 cd(cpath)
 files = dir ('*.vrl');
 files = files([files.isdir] ~= 1);
 fns = {files.name};
 for idays = 1:numel(fns)
    sessiondata(counter).stage_name = flds{istages};
    sessiondata(counter).dir_path = cM.behavior.(flds{istages}).data.directory_path{idays};
    sessiondata(counter).file_name = fns{idays};
    sessiondata(counter).file_ext = fns{idays}(end-3:end);
    sessiondata(counter).file_path = cM.behavior.(flds{istages}).data.file_path{idays};
    sessiondata(counter).trainer_name = cM.experimenter;
    if strcmp(cM.behave_vr_type, 'linmaze')
        sw = 'pyVR'; 
        hw = 'simple gramophone';
    elseif strcmp(cM.behave_vr_type, 'moculus')
        sw = 'unity';
        hw = 'moculus';
    else
        sw = 'matlab';
        hw = 'basic gramophone';
    end
    sessiondata(counter).sw = sw;
    sessiondata(counter).hw = hw;
    counter = counter + 1;
end
end
if ~exist('sessiondata', 'var')
    disp('Behavior directory paths are emtpy! The function terminates.');
    return
end
% order sessiondata into alphabetic by stag_name field
[~, idx] = sort({sessiondata.stage_name});
sessiondata = sessiondata(idx);

% behave2hdf5
for isessions = 1:size(sessiondata,2)
    vr_type = cM.behave_vr_type;
    cS = vrlog2struct_hg(sessiondata(isessions).file_path, vr_type);
    behave2hdf5(floc, cS, isessions, sessiondata);
end

% provide the h5info as output
info = h5info(floc);