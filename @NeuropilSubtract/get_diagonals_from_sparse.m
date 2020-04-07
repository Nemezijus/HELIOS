function mat_dict = get_diagonals_from_sparse(obj,mat)
%unlike in Python this function returns a struct rather than a dictionary
%see https://allensdk.readthedocs.io/en/latest/_modules/allensdk/brain_observatory/r_neuropil.html#NeuropilSubtract
[Bout,id] = spdiags(mat);
for iid = 1:numel(id)
    mat_dict(iid).key = id(iid);
    mat_dict(iid).value = Bout(:,iid);
end