function [mask, pixelidx] = roimask(POLY, IMG)
% [mask, pixelidx] = roimask(POLY, IMG) - creates ROI mask for the given coordinates in
% POLY based on the image IMG dimensions;
% POLY has to be two row matrix
% part of HELIOS
sz = size(IMG);
xdim = sz(1);
ydim = sz(2);

xpoly = POLY(1,:);
ypoly = POLY(2,:);
%removing NaNs
xpoly = xpoly(~isnan(xpoly));
ypoly = ypoly(~isnan(ypoly));
% plot(xpoly, ypoly,'w-'); mask = []; pixelidx = []; return

maskBuffer = logical(poly2mask(xpoly,ypoly,xdim,ydim));
mask = imdilate(maskBuffer,strel('disk',1));
CC = bwconncomp(mask);

pixelidx = uint64(CC.PixelIdxList{1, 1});
