function s = stimulus_protocol(name,newstimstruct)
% S = stimulus_protocol(name,newstimstruct) - load or create a new stimulus protocol

loc = 'N:\DATA\Betanitas\!Mouse Gramophon\HUB_root\stim_prot.txt';

%PARSING THE STIM_PROT text file
fileID = fopen(loc,'r');
C = textscan(fileID, '%s', 'Delimiter', '\n');
fclose(fileID);
newStr = join(C{:},' ');
newStr = newStr{:};
stimuli = extractBetween(newStr,'<stim_define_start>','<stim_define_end>');

for istim = 1:numel(stimuli)
    ss = stimuli{istim};
    ss = erase(ss, ' ');
    subs = strsplit(ss, ';');
    for isub = 1:numel(subs)
        csub = subs{isub};
        if ~isempty(csub)
            fieldname = extractBefore(csub,'=');
            value = extractAfter(csub,'=');
            if strcmp(fieldname, 'stimulus_name')
                persistent_name = ['st_',value];
            else
                S.(persistent_name).(fieldname) = str2double(value);
            end
        end
    end
end

stim_names = fieldnames(S);
if nargin == 0
    s = S;
    return
end
if ismember(name, stim_names)
    s = S.(name);
    return
end
fnames = fieldnames(newstimstruct);
fileID = fopen(loc,'a+');
fprintf(fileID,'%s\n','');
fprintf(fileID,'%s\n', '<stim_define_start>');
fprintf(fileID,'\t%s\n',['stimulus_name = ',name,';']);
try
    for ifn = 1:numel(fnames)
        fprintf(fileID,'\t%s\n',[fnames{ifn},' = ',num2str(newstimstruct.(fnames{ifn})),';']);
    end
catch
    disp('didnt work')
end
fprintf(fileID,'%s', '<stim_define_end>');
fclose(fileID);
s = newstimstruct;