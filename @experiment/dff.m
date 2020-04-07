function ex = dff(ex, method, tostitch)
% ex = dff(ex, method, tostitch) - performs dff on the experiment object
% and stores the results to the hdf5 file. ex object must contain entries
% for setup and stimtype fields!
% part of HELIOS
E = ex.dffparams;
root = '/ANALYSIS';
stitchstr = '';
tic
if tostitch
    stitchstr = '_stitched';
    for iroi = 1:ex.N_roi
        path = strjoin({root, ['ROI_',num2str(iroi)]},'/');
        for istage = 1:ex.N_stages
            path = strjoin({root, ['ROI_',num2str(iroi)],['STAGE_',num2str(istage)]},'/');
            st = ex.stitch(iroi, istage, 'raw');
            stdff = st.dff(method, E);
            ustdff = stdff.unstitch(ex);
            store(ustdff, ex);
            for istim = 1:ex.N_stim(istage)
                path = strjoin({root, ['ROI_',num2str(iroi)],['STAGE_',num2str(istage)],['STIM_',num2str(istim)]},'/');
                for irep = 1:ex.N_reps(istage)
                    UNIT(irep) = ex.restun{istage}(istim,irep);
                end
                h5writeatt(ex.file_loc,path,'UNITNUMBER',UNIT);
            end
        end
    end
    toc
else
    for iroi = 1:ex.N_roi
        path = strjoin({root, ['ROI_',num2str(iroi)]},'/');
        for istage = 1:ex.N_stages
            path = strjoin({root, ['ROI_',num2str(iroi)],['STAGE_',num2str(istage)]},'/');
            for istim = 1:ex.N_stim(istage)
                path = strjoin({root, ['ROI_',num2str(iroi)],['STAGE_',num2str(istage)],['STIM_',num2str(istim)]},'/');
                for irep = 1:ex.N_reps(istage)
                    w = traces(ex,{iroi, istage, istim, irep},'raw');
                    d = w.dff(method,E);
                    D(irep,:) = d.data;
                    UNIT(irep) = ex.restun{istage}(istim,irep);
                end
                cpath = [path,'/DFF'];
                try
                    allocatespace(ex.file_loc, {D}, {cpath});
                catch
                end
                storedata(ex.file_loc, {D}, {cpath});
                clear D
                h5writeatt(ex.file_loc,path,'UNITNUMBER',UNIT);
            end
        end
    end
    toc
end
h5writeatt(ex.file_loc,root,'DFFTYPE',[method, stitchstr]);
h5writeatt(ex.file_loc,root,'DFFMODDATE',datenum(now));
h5writeatt(ex.file_loc,root,'DFFMODUSER',getenv('username'));
ex = experiment(ex.file_loc);