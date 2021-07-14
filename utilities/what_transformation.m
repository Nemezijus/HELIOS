function [R, T, rotmat] = what_transformation(A, B)
% [R, T, rotmat] = what_transformation(A, B) - find the rotation and translation
% values that transform dataset A to dataset B

szA = size(A);
szB = size(B);

if szA(2) < 3
    A(1:szA(1),3) = 0;
end
if szB(2) < 3
    B(1:szB(1),3) = 0;
end
%centroids
cA = centroid(A);
cB = centroid(B);

H = (A - cA)'*(B - cB);
[U,S,V] = svd(H);
R = V*U';
T = cB - (R*cA')';

% rx = atan2(R(3,2), R(3,3));
% ry = atan2(-R(3,1), sqrt(R(3,2)^2 + R(3,3)^2));
% rz = atan2(R(2,1), R(1,1));

E2 = - asin(R(1,3));
E1 = atan2(R(2,3)/cos(E2), R(3,3)/cos(E2));
E3 = atan2(R(1,2)/cos(E2), R(1,1)/cos(E2));
rotmat = R;
R = rad2deg([E1,E2,E3]);

function c = centroid(m)
N = numel(m(:,1));
c = sum(m)./N;