function cwin = coswin(rdim,cdim,support)
% cosine window that smooths out borders of image before filtering
%
% History:
% Date      Who     What
%--------   ------- ---------------------------------
% 04/2002   RE      Touched.
% 05/2000   OP      Create.

n  = [0:support-1];  
cosseq = 0.5*(cos(pi*n/support+pi)+1);

cwin = ones(rdim,cdim);
cwin(1:support,:)=cosseq'*ones(1,cdim);
cwin(rdim-support+1:rdim,:)=flipud(cosseq')*ones(1,cdim);
cwin(:,1:support) = cwin(:,1:support).*(ones(rdim,1)*cosseq);
cwin(:,cdim-support+1:cdim) = cwin(:,cdim-support+1:cdim).* ...
    (ones(rdim,1)*fliplr(cosseq));