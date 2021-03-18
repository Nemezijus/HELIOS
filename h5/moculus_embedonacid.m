function out = moculus_embedonacid(file_loc, datapaths, onacidpath, stageids)
% out = moculus_embedonacid(file_loc, datapaths, stageids) - one by one embeds data
% from OnAcid output files in hdf5 file located at file_loc.
% datapaths - the paths to raw data files
% onacidpath - directory containing all OnAcid outputs
% updated for moculus datasets
% part of HELIOS

if numel(stageids) ~= numel(datapaths)
    error('stage identifier number does not match data path number');
end
if isempty(onacidpath)
    error('No OnAcid data has been located');
end
Ndata = numel(datapaths);

onacfiles = dir(onacidpath);
onacfiles = onacfiles(~[onacfiles.isdir]);

for ifile = 1:numel(onacfiles)
    cname = onacfiles(ifile).name;
    if contains(cname,'after')
        roilocation = fullfile(onacfiles(ifile).folder, onacfiles(ifile).name);
        break
    end
end

for idata = 1:Ndata
    cpath = datapaths{idata};
    disp(['Extracting base information from mesc files for day ',num2str(idata)]);
    tic,
    data = miniresonantExporter(cpath,roilocation);
    t = toc;
    disp(['DONE. Time spent: ',num2str(t)]);
    stagetag.id = stageids{idata};
    stagetag.idx = idata;
    disp(['storing data from stage ', num2str(idata)]);
    out = moculus_datareduced2hdf5(file_loc, data, stagetag);
end