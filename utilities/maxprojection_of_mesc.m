function [MP,maxproj] = maxprojection_of_mesc(mescloc)
% function [MP,maxproj] = maxprojection_of_mesc(mescloc) - creates a maximum
% projection from a mesc file in mescloc location
% part of HELIOS
MP = [];

info = h5info(mescloc);
data = info.Groups.Groups;
for idata = 1:numel(data)
    nameCh = [data(idata).Name,'/',data(idata).Datasets.Name];
    frameSet = 65535-flip(h5read(mescloc,['',nameCh]),2);
    framePool = uint32(zeros([size(frameSet,1) size(frameSet,2) 1]));
    
    MP(idata).geomTrans = double(h5readatt(mescloc,data(idata).Name,'GeomTransTransl'));
    MP(idata).convX = double(h5readatt(mescloc,data(idata).Name,'XAxisConversionConversionLinearScale'));
    MP(idata).convY = double(h5readatt(mescloc,data(idata).Name,'YAxisConversionConversionLinearScale'));
    
    upper = h5readatt(mescloc,data(idata).Name,'Channel_0_Conversion_UpperLimitUint16');
    offset = h5readatt(mescloc,data(idata).Name,'Channel_0_Conversion_ConversionLinearOffset');
    offset = double(upper-offset);
    LUT = h5readatt(mescloc,data(idata).Name,'Channel_0_LUT_VecBounds');
    stage = round(LUT(end)) - round(LUT(1));
    greenVec = linspace(0,1,stage);
    Vec = zeros(upper,1)';
    try
        Vec(round(LUT(1)) : round(LUT(1))+stage-1) = greenVec;
    catch
        Vec(round(LUT(1))+1 : round(LUT(1))+stage) = greenVec;
    end
    Vec(round(LUT(end)) : upper) = 1;
    
    LUT = [zeros(upper,1)';Vec;zeros(upper,1)']';
    for j = 1:size(frameSet,3) %% frame
        I = frameSet(:,:,j);
        frameOffset = I - offset;
        framePool = framePool + uint32(frameOffset);
    end
    MP(idata).meanPic = uint16(framePool/(size(frameSet,3)));
    MP(idata).LUT = LUT;
    clear frameSet framePool
end

for frame = 1:numel(data)
    frameSet(:,:,frame)= MP(frame).meanPic;
end

maxproj = max(frameSet,[],3);