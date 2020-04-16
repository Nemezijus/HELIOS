function OB = subtractbg(OB, info)
% OB = subtractbg(OB, info) - subtracts background/neuropil from the
% rawdata and estimates df/f from the adjusted waveforms. The raw data
% values are not overwritten, only df/f is stored. info - parameter struct.
% part of HELIOS
if nargin < 2
    info.bgcorrmethod = 'linear';
    info.dffmethod = 'median';
    info.tostitch = 1;
end
root = '/ANALYSIS';
E = OB.dffparams; %dff parameter struct
for istage = 1:OB.N_stages
    disp(['BG correction on stage ', num2str(istage),' in progress...']);
    for iroi = 1:OB.N_roi
        if info.tostitch
            Y = stitch(OB, iroi, istage, 'raw');
            bg = stitch(OB, iroi, istage, 'bg');
            switch info.bgcorrmethod
                case 'linear'
                    corrected = Y.data - bg.data;
                case 'contaminationr'
                    [corrected, NP] = neuropil_contamination_correction(Y.data, bg.data, 0);
            end
            Y.data = corrected;
            stdff = Y.dff(lower(info.dffmethod), E);
            ustdff = stdff.unstitch(OB);
            store(ustdff, OB);
            
            Nstim = OB.N_stim(istage);
            Nreps = OB.N_reps(istage);
            for istim = 1:Nstim
                for irep = 1:Nreps
                    UNIT(irep) = OB.restun{istage}(istim,irep);
                end
                path = strjoin({root, ['ROI_',num2str(iroi)],['STAGE_',num2str(istage)],['STIM_',num2str(istim)]},'/');
                h5writeatt(OB.file_loc,path,'UNITNUMBER',UNIT);
            end
        else
            Nstim = OB.N_stim(istage);
            Nreps = OB.N_reps(istage);
            for istim = 1:Nstim
%                 
                    Y = traces(OB, {iroi,istage,istim,0},'raw');
                    bg = traces(OB, {iroi,istage,istim,0},'bg');
                    switch info.bgcorrmethod
                        case 'linear'
                            corrected = Y.data - bg.data;
                        case 'contaminationr'
                            for irep = 1:Nreps
                                [corrected(irep,:), NP(irep)] = neuropil_contamination_correction(Y.data(irep,:), bg.data(irep,:), 0);
                            end
                    end
                    Y.data = corrected;
                    stdff = Y.dff(lower(info.dffmethod), E);
                    store(stdff, OB);
                    for irep = 1:Nreps
                        UNIT(irep) = OB.restun{istage}(istim,irep);
                    end
                    path = strjoin({root, ['ROI_',num2str(iroi)],['STAGE_',num2str(istage)],['STIM_',num2str(istim)]},'/');
                    h5writeatt(OB.file_loc,path,'UNITNUMBER',UNIT);
            end
        end
    end
end
OB = experiment(OB.file_loc);