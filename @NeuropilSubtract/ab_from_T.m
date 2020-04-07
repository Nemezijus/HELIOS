function [ab, M] = ab_from_T(obj,T, lam, dt)
e = ones(T-1);
Ls = -speye(T-1,T) + spdiags(e,1,T-1,T);
Ls = Ls./dt;
Ls2 = Ls'*Ls;
M = speye(T) + lam .* Ls2;
mat_dict = get_diagonals_from_sparse(obj,M); %this is a struct
ab = ab_from_diagonals(obj, mat_dict);