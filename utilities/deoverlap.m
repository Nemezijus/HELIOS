function Rclean = deoverlap(R)
% Rclean = deoverlap(R) - combines ROIs from multiple RR structs and
% excludes overlaps
%R should have a field called 'set' which contains the RR struct from one
%processing

Nsets = numel(R);

Nlayers = numel(R(1).set); %must be the same for all the sets
%implement the check for that
warning('off','MATLAB:polyshape:repairedBySimplify');
p = polygonize(R, Nsets, Nlayers);

for iset = 2:Nsets
    for ilayer = 1:Nlayers
        Nrois = numel(R(iset).set(ilayer).R);
        for iroi = 1:Nrois
            overlapping = 0;
            poly1 = p.layer(ilayer).set(iset).roi(iroi).ps; %new set roi shape
            
            Nrois_ref = numel(R(1).set(ilayer).R);
            
            for iroi_ref = 1:Nrois_ref
                poly_ref = p.layer(ilayer).set(1).roi(iroi_ref).ps;
                
                polyvec = [poly1, poly_ref];
                TF = overlaps(polyvec);
                
                if TF(1,2) == 1
                    overlapping = 1;
                    break
                end
            end
            if ~overlapping
                R(1).set(ilayer).R(numel(R(1).set(ilayer).R)+1) = R(iset).set(ilayer).R(iroi);
                p = polygonize(R, Nsets, Nlayers);
            end
            
        end
    end
    
end
warning('on','MATLAB:polyshape:repairedBySimplify');
Rclean = R(1).set;

function p = polygonize(R, Nsets, Nlayers)
for ilayer = 1:Nlayers
    %Rclean(ilayer).R = R(1).set(ilayer).R;
    for iset = 1:Nsets
        Nrois = numel(R(iset).set(ilayer).R);
        for iroi = 1:Nrois
            p.layer(ilayer).set(iset).roi(iroi).ps = polyshape(R(iset).set(ilayer).R(iroi).pseudo(2,:),R(iset).set(ilayer).R(iroi).pseudo(1,:));
        end
    end
end

% for ilayer = 1:Nlayers
%     counter = 1;
%     for iset = 1:Nsets-1
%         for iroi1 = 1:numel(R(iset).set(ilayer).R)
%             poly1 = p.layer(ilayer).set(iset).roi(iroi1).ps;
%             for iset2 = iset+1:Nsets
%                 for iroi2 = 1:numel(R(iset2).set(ilayer).R)
%                     poly2 = p.layer(ilayer).set(iset2).roi(iroi2).ps;
%                     polyvec = [poly1, poly2];
%                     TF = overlaps(polyvec);
%                     if TF(1,2) == 0
% %                         R.clean(counter) = 
%                     end
%                 end
%             end
%         end
%     end
% end