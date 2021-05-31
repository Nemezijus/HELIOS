function PROJ = multilayer_projections(fpath, Nlayers, units)
%collects maximum projections of the .h5 file (fpath) into a PROJ struct.
%Nlayers - number of imaging layers
%the .h5 structure is assumed to be that of mesc file

info = h5info(fpath);
Nunits = numel(info.Groups.Groups);

chan_string = 'Channel_0';
if nargin < 3
    units = 1:Nunits;
end
for iunit = units
    disp(['Working on Unit ', num2str(iunit),'/', num2str(numel(units))]);
    cunit = info.Groups.Groups(iunit);
    data = h5read(fpath,[cunit.Name,'/',chan_string]);
    nFrames = numel(data(1,1,:));
    for ilayer = 1:Nlayers
        d = data(:,:,ilayer:Nlayers:end);
        seq = 1:numel(data(1,1,:));
        
        clayer_data(:,:) = sum(d,3)./numel(d(1,1,:));
        if iunit == 1
            PROJ(ilayer).mean = clayer_data;
        else
            PROJ(ilayer).mean = PROJ(ilayer).mean + clayer_data;
        end
        PROJ(ilayer).unit(iunit).frames = seq(ilayer:Nlayers:end);
        clear clayer_data
    end
end
for ilayer = 1:Nlayers
    PROJ(ilayer).mean = uint16(imrotate(PROJ(ilayer).mean./Nunits,90));
    greenVec = linspace(0,1,65535);
    gmap = [zeros(65535,1)';greenVec;zeros(65535,1)']';
    [newLUT, newIMG] = visc_reLUT(PROJ(ilayer).mean, gmap, 0);
    PROJ(ilayer).image = newIMG;
    PROJ(ilayer).LUT = newLUT;
end
