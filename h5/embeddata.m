function out = embeddata(file_loc, datapaths, stageids)
% out = embeddata(file_loc, datapaths, stageids) - one by one embeds data
% from data.mat files in hdf5 file located at file_loc.
% datapaths - all the paths to data.mat structures identified with
% corresponding stageids
% part of HELIOS

if numel(stageids) ~= numel(datapaths)
    error('stage identifier number does not match data path number');
end

Ndata = numel(datapaths);

for idata = 1:Ndata
    cpath = datapaths{idata};
    stagetag.id = stageids{idata};
    stagetag.idx = idata;
    S = load(cpath);
    fn = fieldnames(S);
    data = S.(fn{:});
    disp(['storing data from stage ', num2str(idata)]);
    out = data2hdf5(file_loc, data, stagetag);
end