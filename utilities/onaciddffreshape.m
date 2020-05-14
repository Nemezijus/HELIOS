function DFF = onaciddffreshape(dff, Ndays, Nrecs, Nsamples)
% dff = onaciddffreshape(dff, Ndays, Nrecs, Nsamples) - splits OnAcid dff
% contcatenated traces into individual curves for further processing.

if numel(Nrecs) == 1
    Nrecs = repmat(Nrecs,1, Ndays);
end

if numel(Nsamples) == 1
    Nsamples = repmat(Nsamples, 1, Ndays);
end

Nroi = numel(dff(:,1));

for iroi = 1:Nroi
    ctrace = dff(iroi,:);
    for iday = 1:Ndays
        Ncurrsamples = Nsamples(iday)*Nrecs(iday);
        cdaytrace = ctrace((iday-1)*Ncurrsamples+1:iday*Ncurrsamples);
        for irec = 1:Nrecs(iday)
            DFF(iroi).stage(iday).signal(irec,:) = cdaytrace((irec-1)*Nsamples(iday)+1:irec*Nsamples);
        end
    end
end