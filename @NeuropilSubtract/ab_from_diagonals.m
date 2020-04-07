function ab =  ab_from_diagonals(obj,mat_dict)
offsets = [mat_dict.key];
l = -min(offsets);
u = max(offsets);
T = size(mat_dict(1).value,1);
ab = zeros([l + u + 1, T]);
for o = offsets
    index = u - o;
    ab(index+1,:) = mat_dict([mat_dict.key]==o).value;
end
