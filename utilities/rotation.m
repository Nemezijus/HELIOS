function rotated = rotation(points, angle, xoffset, yoffset)
% rotated = rotation(points, angle, xoffset, yoffset) - returns the rotated
% coordinate points by a specified angle.
% Rotation assumes the original points being in the first quadrant of the
% Cartesian axes. Offsets x and y can adjust for that, if this is not a
% case.
if nargin < 4
    yoffset = 0;
end

if nargin < 3
    xoffset = 0;
end
Poffset = points - [xoffset, yoffset];

rotmat = [cosd(angle) -sind(angle); sind(angle) cosd(angle)];

rotated = Poffset*rotmat;
rotated = rotated + [xoffset, yoffset];