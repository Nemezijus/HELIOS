function hrf = findhrf(id);
% hrf = findhrf(id) - looks up and loads the HUB root file which matches
% experiment id. Location of HUB root files is hardcoded here
% part of HELIOS

hrfloc = 'N:\DATA\Betanitas\!Mouse Gramophon\HUB_root';

contents = dir(hrfloc);
contents = contents(~[contents.isdir]);
location = ismember({contents.name},['m',id,'.mat']);

hrfloc = fullfile(contents(location).folder, contents(location).name);
hrf = load(hrfloc);
fns = fieldnames(hrf);
hrf = hrf.(fns{:});

