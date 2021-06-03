function S = stitch(OB, iroi, istage, type)
% S = stitch(ex, iroi, istage, type) - stitches the split waveforms of a
% given roi (iroi) for a given day (istage). type - a string flag
% indicating which type of waveforms should be stitched (e.g. 'raw'
% {default}, 'dff')
%part of HELIOS
if nargin < 4
    type = 'raw';
end
if nargin < 3
    istage = 1;
end
if nargin < 2
    iroi = 1;
end

count = 1;
for ir = 1:numel(iroi)
    for is = 1:numel(istage)
        switch type
            case {'raw', 'bg'}
                W = traces(OB,{iroi(ir) istage(is) 0 0},type);
                Ts = 1./W.Fs(1)*1e-3;%sampling period
                all_unit_index = find(contains(W.tag,'UNIT_'));
                unit_strings = W.tag(all_unit_index);
                numcells = regexp(unit_strings,'\d+(\.)?(\d+)?','match');
                units = str2double([numcells{:}])';
                units = units(units>0); %added 2020-11-04
            case 'dff'
                W = traces(OB,{iroi(ir) istage(is) 0 0},type);
                Ts = 1./W.Fs(1)*1e-3;%sampling period
                units = [];
                try
                for itag = 1:numel(W.tag(:,1))
                    subunits = h5readatt(OB.file_loc, strjoin(W.tag(itag,:),'/'), 'UNITNUMBER');
                    subunits = subunits(subunits>0);%added 2020-11-04
                    units = vertcat(units,subunits);
                end
                catch
                    units = [1:numel(W.tag(:,1))];
                end
            case 'behavior'
                B = OB.behavior;
                if isempty(B)
                    disp('No behavior data embedded!')
                    return
                end
                S = stitch_behavior(B,OB,istage);
                return
        end
        data_st(count,:) = stitchrows(W.data, units,'data',OB.setup,Ts);
        time_st(count,:) = stitchrows(W.time, units,'time',OB.setup,Ts);
        tag{count} = W.tag;
%         tag{count} = strjoin({'',['ROI_',num2str(iroi(ir))],['STAGE_',num2str(istage(is))]},'/');
        count = count+1;
    end
end
S = waveform(data_st, time_st, W.data_type, W.time_units, W.data_units, tag);




function st = stitchrows(in, order, type, setup, Ts)
nelements = numel(in(1,:));
st = zeros(1,prod(size(in)));
switch type
    case 'data'
        for io = 1:numel(order)
            trace = in(io,:);
            switch setup
                case 'ao'
                    cutoff = 500;
                    N_cutoffsampl = ceil(cutoff/Ts);
                    trace(end-N_cutoffsampl:end) = deal(trace(end-N_cutoffsampl-1));
                    trace(1) = trace(2); %a dirty fix for photostim/long recordings having first sample artifact [2021-05-12]
                otherwise
                    trace(1) = trace(2);%the treatment of first sample, for AO we need different method
            end
            
            st((order(io)-1)*nelements+1:(order(io)-1)*nelements+nelements) = trace;
        end
    case 'time'
        for io = 1:numel(order)
            st((order(io)-1)*nelements+1:(order(io)-1)*nelements+nelements) = in(io,end).*(order(io)-1)+(in(io,2)*order(io)-1)+in(io,:);
        end
        st = st - in(1,2)+1;
end

function S = stitch_behavior(B,OB,ist)
b = B.stage(ist);
Nunits = 1:numel(b.unit);

for iunit = Nunits
    w = traces(OB, {1,ist,[],[],iunit},'dff');
    trace_time = w.time;
    switch w.time_units %force to be in seconds
        case 'us'
            trace_time = trace_time .* 1e-6;
        case 'ms'
            trace_time = trace_time .* 1e-3;
        case 's'
            trace_time = trace_time;
        otherwise
            error('unknown time units')
    end
    trace_length = trace_time(end);%seconds
    cb = b.unit(iunit);
    mask = cb.time>= cb.time_offset & cb.time <= trace_length + cb.time_offset;
    if cb.time_offset < 1
        disp(['For unit ', num2str(iunit),' time offset is less than 1 second! Investigate.']);
    end
    if iunit == 1
        beh_time = cb.time(mask)';
        beh_data = cb.velocity(mask)';
    else
        cleaned_time = cb.time(mask)';
        cleaned_time = cleaned_time-cleaned_time(1);
        beh_time = horzcat(beh_time,cleaned_time+beh_time(end)+cleaned_time(2));
        beh_data = horzcat(beh_data,cb.velocity(mask)');
    end
end
S = waveform(beh_data, beh_time, 'velocity', 's', 'dm/s', 'behavior_velocity');