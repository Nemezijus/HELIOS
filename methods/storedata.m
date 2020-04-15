function storedata(fl, data, paths)
% storedata(fl, data, paths) - overwrites or stores data in the hdf5 file
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
    if ~isempty(cdata)
        h5write(fl, paths{idata}, cdata);
    end
end