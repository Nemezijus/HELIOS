function OB = subtractbg(OB, info)
% OB = subtractbg(OB, info) - subtracts background/neuropil from the
% rawdata and estimates df/f from the adjusted waveforms. The raw data
% values are not overwritten, only df/f is stored. info - parameter struct.
% part of HELIOS
if nargin < 2
    info.bgcorrmethod = 'linear';
    info.dffmethod = 'median';
end
E = OB.dffparams; %dff parameter struct
for istage = 1:OB.N_stages
    disp(['BG correction on stage ', num2str(istage),' in progress...']);
    for iroi = 1:OB.N_roi
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
    end
end
