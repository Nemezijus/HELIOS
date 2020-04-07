classdef roi
%roi class. Stores roi mask, squared area mask around roi, number of pixels
%used to create square mask and more
    properties
        roi_mask
        N_pixels_for_square_mask
        square_mask
        close_to_border
        mask_around_roi
    end
    methods
        function obj = roi(mask,N)
            if nargin < 2
                N = 5;
            end
            obj.roi_mask = mask;
            obj.N_pixels_for_square_mask = N;
            obj = obj.square;
        end
    end
end