function out = moculus_embeddata(file_loc, datapaths, stageids, behavior_files)
% out = moculus_embeddata(file_loc, datapaths, stageids, behavior) - one by one embeds data
% from data.mat files in hdf5 file located at file_loc.
% datapaths - all the paths to data.mat structures identified with
% corresponding stageids
% behavior files - cell with links to behavior csv files
% adapted for Moculus project
% part of HELIOS
if ~isempty(datapaths)
    if numel(stageids) ~= numel(datapaths)
        error('stage identifier number does not match data path number');
    end
    
    if numel(datapaths) ~= numel(behavior_files)
        error('the number of data files and behavior files does not match!');
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
        out = moculus_data2hdf5(file_loc, data, stagetag, behavior_files{idata});
    end
else
    for idata = 1:numel(behavior_files)
        stagetag.id = stageids{idata};
        stagetag.idx = idata;
        out = moculus_data2hdf5(file_loc, [], stagetag, behavior_files{idata});
    end
end