function [Gj] = expand(Gi,dim)

rr = dim(1);
cc = dim(2);
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

[NRe NCe] = size(E);

%====================================
% upsample and interpolate 
% intermediate points
%====================================

Ginterp = imresize(E,[(rr+8) (cc+8)],'bilinear');

%======================================
% cut out central portion corresponding
% to upsampled original image
%======================================
Gj = Ginterp(5:5+rr-1,5:5+cc-1);