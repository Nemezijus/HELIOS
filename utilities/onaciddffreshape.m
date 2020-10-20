function DFF = onaciddffreshape(dff, Ndays, Nrecs, Nsamples, Nreps)
% dff = onaciddffreshape(dff, Ndays, Nrecs, Nsamples, Nreps) - splits OnAcid dff
% contcatenated traces into individual curves for further processing.

if numel(Nrecs) == 1
    Nrecs = repmat(Nrecs,1, Ndays);
end

if numel(Nsamples) == 1
    Nsamples = repmat(Nsamples, 1, Ndays);
end

Nroi = numel(dff(:,1));


for iroi = 1:Nroi
    accumsamples = 0;
    ctrace = dff(iroi,:);
    for iday = 1:Ndays
        Ncurrsamples = Nsamples(iday)*Nrecs(iday);
        from = accumsamples+1;
        to = accumsamples+(Ncurrsamples);
        cdaytrace = ctrace(from:to);
        for irec = 1:Nrecs(iday)
            DFF(iroi).stage(iday).signal(irec,:) = cdaytrace((irec-1)*Nsamples(iday)+1:irec*Nsamples(iday));
        end
        accumsamples = accumsamples+Ncurrsamples;
    end
end