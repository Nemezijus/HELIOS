function WAV = datastruct2waveform(data,implant)
% WAV = datastruct2waveform(data) - creates waveform objects from
% old VISC data structs.
%
% data - the data struct itself
% the Ca traces should be located in data.CaTransient.event level
%
%part of HELIOS
if nargin < 2
    implant = 0;
end
Nsessions = numel(data);

for isess = 1:Nsessions
    NROIs = numel(data(isess).CaTransient);
    for iroi = 1:NROIs
        x = data(isess).CaTransient(iroi).event(1,:);
        y = data(isess).CaTransient(iroi).event(2,:);
        data_type = 'raw';
        time_units = 'ms';
        data_units = 'a.u';
        tag = num2str(['sess_',num2str(isess),'_roi_',num2str(iroi)]);
        wav = waveform(y, x, data_type, time_units, data_units, tag);
        if implant
            data(isess).CaTransient(iroi).waveform = wav;
        else
            WAV(isess).ROI(iroi) = wav;
        end
    end
end

if implant
    WAV = data;
end