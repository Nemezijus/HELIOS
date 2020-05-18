function storeonaciddff(OB, dff, stimlist, stimsequence)
% storeonaciddff(OB, dff, stimlist, stimsequence) - stores the reshaped OnAcid dff struct
% in the h5 file. Stimlist - a sequence of stimuli identifiers till the
% pattern repeats. OB - experiment object.
% part of HELIOS

if nargin < 4
    stimsequence = sort(unique(stimlist));
    odd = stimsequence>360;
    stimseq = stimsequence(odd);
    stimseq = [stimseq, stimsequence(~odd)];
    stimsequence = stimseq;
end

root = '/ANALYSIS';

for iroi = 1:numel(dff)
    disp(['DFF is being stored for ROI ', num2str(iroi),' / ', num2str(numel(dff))]);
    cpath = [root,'/ROI_',num2str(iroi)];
    for istage = 1:numel(dff(iroi).stage)
        cpath1 = [cpath,'/STAGE_',num2str(istage)];
        
        fullstimlist = repmat(stimlist, 1,ceil(numel(dff(iroi).stage(istage).signal(:,1))/numel(stimlist)));
        for istim = 1:numel(stimsequence)
            cpath2 = [cpath1,'/STIM_', num2str(istim)];
            data = dff(iroi).stage(istage).signal(fullstimlist==stimsequence(istim),:)';
            loc = [cpath2,'/DFF'];
            try
                allocatespace(OB.file_loc, {data}, {loc});
            catch
            end
            storedata(OB.file_loc, {data}, {loc});
            for irep = 1:OB.N_reps(istage)
                UNIT(irep) = OB.restun{istage}(istim,irep);
            end
            path = strjoin({root, ['ROI_',num2str(iroi)],['STAGE_',num2str(istage)],['STIM_',num2str(istim)]},'/');
            h5writeatt(OB.file_loc,path,'UNITNUMBER',UNIT);
        end
    end
end