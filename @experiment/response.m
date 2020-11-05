function R = response(OB, iroi, istage)
% R = response(OB, iroi, istage) - an experiment method, estimating
% response strength (within stimulus window), OSI, number of significant
% peaks inside stimulus window and more. All the results are stored in
% struct R
% part of HELIOS

if nargin < 3
    istage = 0;
end

if istage == 0
    stages = 1:OB.N_stages;
else
    stages = istage;
end
E = OB.dffparams;
count = 1;
%initialize NaNned R (added 2020-11-04)
R.stimulus(1:numel(stages),1:max(OB.N_stim)) = NaN;
R.strength(1:numel(stages),1:max(OB.N_stim)) = NaN;
R.stimwinsd(1:numel(stages),1:max(OB.N_stim),1:max(OB.N_reps)) = NaN;
for is = stages
    %stimuli time stamps
    stimtype = h5readatt(OB.file_loc,['/DATA/STAGE_',num2str(is)],'STIMTYPE');
    stimuli = h5readatt(OB.file_loc,['/DATA/STAGE_',num2str(is)],'STIMLIST')';
    stageID = h5readatt(OB.file_loc,['/DATA/STAGE_',num2str(is)],'STAGEID');
    S = stimlist(stimtype);
    
    Nstim = OB.N_stim(is);
    R.stage{count} = stageID;
    for istim = 1:Nstim
        W = OB.traces({iroi, is, istim, 0},'dff');
        stimmask = W.time(1,:) >= S.static1 & W.time(1,:) <= S.blank2;
        cY = W.data(:,stimmask);
        meancY = mean(cY,2);
        meansum = sum(meancY);
        R.stimulus(count,istim) = stimuli(istim);
        R.strength(count, istim) = mean(meancY);
        R.stimwinsd(count,istim,1:numel(cY(:,1))) = std(cY,[],2);
        %         R.meansum(is, istim) = meansum;
        
    end
    count = count+1;
end

%OSI
count = 1;
for is = stages
    stimuli = R.stimulus(count,:);
    strengths = R.strength(count,:);
    stimmask = stimuli <= 360;
    good_stimuli = stimuli(stimmask);
    good_strengths = strengths(stimmask);
    max_strength = max(good_strengths);
    remaining_strengths = setdiff(good_strengths,max_strength);
    
    R.osi(count) = (max_strength - mean(remaining_strengths))./(max_strength + mean(remaining_strengths));
    R.dominantstimulus(count) = good_stimuli(good_strengths == max(good_strengths));
    count = count+1;
end

%SIGNIFICANT PEAKS
count = 1;
for is = stages
    Nstim = OB.N_stim(is);
%     Nreps = OB.N_reps(is);
    
    ST = stitch(OB, iroi, is, 'dff');
    [~, si] = visc_wavenorm(ST.data,ST.time,[],10); %to be adapted separately
    for istim = 1:Nstim
        W = OB.traces({iroi, is, istim, 0},'dff');
        Nreps = numel(W.data(:,1));
        for irep = 1:Nreps
            THR = significant_peaks(W.data(irep,:), W.time(irep,:), si, S, 1, 0);
            R.peaksinstimwin(count,istim,irep) = THR.stim_peaks;
            R.peakmask(count,istim,irep,:) = THR.Xmasknan;
        end
        %HERE REFER TO CODE FOR PEAK DETECTION visc_dffcriteria
        
    end
    count = count+1;
end