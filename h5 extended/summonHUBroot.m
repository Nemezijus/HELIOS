function [Hrfn, cMouse] = summonHUBroot(input_chr)
% [Hrfn, cMouse] = summonHUBroot() returns with the actual list of animals
% in the HUB_root folder (Hrfn) 

%STEP1
Hr = 'N:\DATA\Betanitas\!Mouse Gramophon\HUB_root';
Hrf = dir(Hr);
Hrf = Hrf(~ismember({Hrf.name}, {'.', '..'}));
Hrfn = cellfun(@(x)x(2:end-4),{Hrf.name},'UniformOutput', false);

%STEP2
if any(ismember(Hrfn, input_chr))
    idx = find(strcmp(Hrfn, input_chr));
    mouse = load([Hrf(idx).folder, '\', Hrf(idx).name]);
    mouse_name = Hrf(idx).name;
    mouse_name = mouse_name(1:end-4);
    cMouse = mouse.(mouse_name);
else
    disp('Sorry, but this mouse is not a member of HUB.');
end