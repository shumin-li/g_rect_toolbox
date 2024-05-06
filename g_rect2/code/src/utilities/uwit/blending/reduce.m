function [Gj] = reduce(Gi)
a = 0.4;
w = [(1/4-a/2) 1/4 a 1/4 (1/4-a/2)];

[NrRows NrCols] = size(Gi);

%==================================
% E is the extrapolated image which
% imposes boundary conditions
%==================================
E = zeros(NrRows+4,NrCols+4);
E(3:end-2,3:end-2) = Gi;
% top and bottom row
E(2,:) = 2*E(3,:) - E(4,:);
E(1,:) = 2*E(3,:) - E(5,:);
E(end-1,:) = 2*E(end-2,:) - E(end-3,:);
E(end,:)   = 2*E(end-2,:) - E(end-4,:);
% left and right col 
E(:,2) = 2*E(:,3) - E(:,4);
E(:,1) = 2*E(:,3) - E(:,5);
E(:,end-1) = 2*E(:,end-2) - E(:,end-3);
E(:,end)   = 2*E(:,end-2) - E(:,end-4);

%==================================
% F = E*W
% convolve E with the kernel W
% (i.e. W=w*w') seperably
%==================================
[NRe NCe] = size(E);
Nw = length(w);
if 1
    F = zeros(NRe+Nw-1,NCe+Nw-1);
    for ii = 1:NrRows
        F(ii+2,:) = conv(w,E(ii+2,:));
    end
    for jj = 1:NrCols
        F(:,jj+2) = conv(w,F(3:end-2,jj+2));
    end
end

%===================================
% remove extra elements resultant 
% from convolution
%===================================
K = F(Nw:end-Nw+1,Nw:end-Nw+1);

%===================================
% subsample K to obtain the 
% final result
%===================================
Gj = K(1:2:end,1:2:end);