function allocatespace(fl, data, paths)
% allocatespace(fl, data, paths) - allocates space for data in the hdf5 file
% fl in specified paths
% data is either a cell containing matrices or vectors, or a matrix. If it
% is a matrix, each corresponding path has to match one ROW in data matrix.
% part of HELIOS
if iscell(data)
    Ndata = numel(data);
else
    Ndata = numel(data(:,1));
end
if Ndata ~= numel(paths)
    error ('number of data and given paths is not matching')
end

for idata = 1:Ndata
    if iscell(data)
        cdata = data{idata};
    else
        cdata = data(idata,:);
    end
    h5create(fl,paths{idata},size(cdata),'ChunkSize',size(cdata), 'Deflate', 9);
end