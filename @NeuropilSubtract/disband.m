function a = disband(obj,l,u, ab)

mLU = max(l,u);
N = numel(ab(1,:))+mLU;

for ir = 1:N
    for ic = 1:N
        idx = u+ir-ic+1;
        if idx <= 0 || ic <= 0 || idx > numel(ab(:,1)) || ic > numel(ab(1,:))
            a(ir,ic) = 0;
        else
            a(ir,ic) = ab(idx, ic);
        end
    end
end

% 
% for ir = 0:numel(ab(:,1))-1;
%     ir = ir+1;
%     for ic = 0:numel(ab(1,:))-1;
%         ic = ic+1;
%         idx = u+ir-ic;
%         if idx <= 0 || ic <= 0
%             a(ir,ic) = 0;
%         else
%             a(ir,ic) = ab(u+ir-ic, ic);
%         end
%     end
% end
% || idx > numel(ab(1,:))