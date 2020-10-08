function OB = rerun(OB,branchname)
% OB = rerun(OB,branchname) - a quick calculation/fix of some attributes or
% data fields in a given experiment file (OB.file_loc). branchname
% indicates which attribute or data has to be fixed/rerun
% part of HELIOS

switch branchname
    case 'UNITNUMBER'
        root = '/ANALYSIS';
        for istage = 1:OB.N_stages
            for iroi = 1:OB.N_roi
                Nstim = OB.N_stim(istage);
                Nreps = OB.N_reps(istage);
                for istim = 1:Nstim
                    for irep = 1:Nreps
                        UNIT(irep) = OB.restun{istage}(istim,irep);
                    end
                    path = strjoin({root, ['ROI_',num2str(iroi)],['STAGE_',num2str(istage)],['STIM_',num2str(istim)]},'/');
                    h5writeatt(OB.file_loc,path,'UNITNUMBER',UNIT);
                    clear UNIT; %added 2020-05-07
                end
            end
        end
    case 'PEAKSINSTIMWIN'
        root = '/ANALYSIS';
        for iroi = 1:OB.N_roi
            for istage = 1:OB.N_stages
                R = OB.response(iroi,istage);
                pks = squeeze(R.peaksinstimwin);
                for istim = 1:OB.N_stim(istage)
                    loc = ['/ROI_',num2str(iroi),'/STAGE_',num2str(istage),'/STIM_',num2str(istim)];
                    try
                        h5writeatt(OB.file_loc,[root,loc], 'PEAKSINSTIMWIN', pks(istim,:));
                    catch
                        a= 1;
                    end
                end
            end
            disp(['ROI ',num2str(iroi),' done'])
        end
    otherwise
end
disp('reloading experiment object');
OB = experiment(OB.file_loc);
disp('done!')