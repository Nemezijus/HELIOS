function S = stimlist(stimtype)
% S = stimlist(stimtype) - gives a struct with information about vis
%   stimulation parameters used in the setup. type can be 'black' or 'gray',
%   depending on what type of sitmulus was used, black - older, until group
%   19. Newer groups use gray.
knownlist = {'black','gray60Hz','8s_gray60Hz', '13.5s_gray60Hz', '14s_gray60Hz',...
    'spat_truncated_duration_15s'};
if ~ismember(stimtype, knownlist)
    disp(['stimulus type ', stimtype,' is unknown']);
    disp(['Allowed stimuli options are: ']);
    disp(knownlist);
    error('bad stimulus type specified');
end
%time is given in miliseconds

if strcmp(stimtype,'black')
    S.alltimes = [0,6000, 7000, 13000, 14000];
    S.blank1 = 0;
    S.static1 = 6000;
    S.moving = 7000;
    S.static2 = 13000;
    S.blank2 = 14000;
    S.blank1dur = 6000;
    S.stimdur = 8000;
    S.blank2dur = 6000;
    S.total = 20000;
elseif strcmp(stimtype,'gray60Hz')
    S.alltimes = [0,20000, 21000, 27000, 28000];
    S.blank1 = 0;
    S.static1 = 20000;
    S.moving = 21000;
    S.static2 = 27000;
    S.blank2 = 28000;
    S.blank1dur = 20000;
    S.stimdur = 8000;
    S.blank2dur = 7000;
    S.total = 35000;
elseif strcmp(stimtype,'8s_gray60Hz')
    S.alltimes = [0,9000, 10000, 16000, 17000];
    S.blank1 = 0;
    S.static1 = 9000;
    S.moving = 10000;
    S.static2 = 16000;
    S.blank2 = 17000;
    S.blank1dur = 9000;
    S.stimdur = 8000;
    S.blank2dur = 1000;
    S.total = 18000;
elseif strcmp(stimtype,'13.5s_gray60Hz')
    S.alltimes = [0,14050, 15050, 21050, 22050];
    S.blank1 = 0;
    S.static1 = 14050;
    S.moving = 15050;
    S.static2 = 21050;
    S.blank2 = 22050;
    S.blank1dur = 14050;
    S.stimdur = 8000;
    S.blank2dur = 1950;
    S.total = 24000;
elseif strcmp(stimtype,'14s_gray60Hz')
    S.alltimes = [0,14550,15550,21550,22550];
    S.blank1 = 0;
    S.static1 = 14550;
    S.moving = 15550;
    S.static2 = 21550;
    S.blank2 = 22550;
    S.blank1dur = 14550;
    S.stimdur = 8000;
    S.blank2dur = 1450;
    S.total = 24000;
elseif strcmp(stimtype, 'spat_truncated_duration_15s');
    S.alltimes = [0,8000,9000];
    S.blank1 = 0;
    S.static1 = 8000;
    S.moving = 9000;
    S.static2 = 15000;
    S.blank2 = 16000;
    S.blank1dur = 8000;
    S.stimdur = 7000;
    S.blank2dur = 0;
    S.total = 16000;
else error
end