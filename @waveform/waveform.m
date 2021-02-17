classdef waveform
%     clear classes
    properties
        data
        data_type
        data_units
        time
        time_units
        Fs
        tag
    end
    methods
        function obj = waveform(data, time, data_type, time_units, data_units, tag)
            if nargin < 6
                tag = {};
            end
            if nargin < 5
                data_units = NaN;
            end
            if nargin < 4
                time_units = NaN;
            end
            if nargin < 3
                data_type = NaN;
            end
            if nargin < 1
                data = rand(1,100);
                data_units = 'a.u.';
                data_type = 'random';
            end
            obj.data = data;
            if nargin < 2
                time = 1:numel(obj.data);
                time_units = 'samples';
            end
            obj.time = time;
            obj.data_type = data_type;
            obj.time_units = time_units;
            obj.data_units = data_units;
            switch lower(obj.time_units)
                case 'us'
                    time = time.*1e6;
                    obj.Fs = 1./mode(diff(time,[],2),2);
                case 'ms'
                    time = time.*1e3;
                    obj.Fs = 1./mode(diff(time,[],2),2);
                case 's'
                    obj.Fs = 1./mode(diff(time,[],2),2);
                otherwise
                    obj.Fs = NaN;
            end
            obj.tag = tag;
        end
    end
end