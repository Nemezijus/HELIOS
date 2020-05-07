classdef roi
%roi class. Stores roi mask, squared area mask around roi, number of pixels
%used to create square mask and more
% part of HELIOS
    properties
        setup
        roi_mask
        N_pixels_for_square_mask
        square_mask
        close_to_border
        mask_around_roi
    end
    methods
        function obj = roi(exp,iroi,istage,N)
            if nargin < 4
                N = 5;
            end
            roi_mask = h5read(exp.file_loc,['/ANALYSIS/ROI_',num2str(iroi),'/STAGE_',num2str(istage),'/ROIMASK']);
            obj.roi_mask = roi_mask;
            obj.N_pixels_for_square_mask = N;
            obj.setup = exp.setup;
            obj = obj.square(iroi,istage,exp);
            
        end
    end
end