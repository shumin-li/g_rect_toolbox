function N = lutmapper(M,ylcmap,xlcmap,indvec)
% maps cartesian spectrum to log-polar VERY VERY quickly
% OP 22-APR-2000
% ylcamp,xlcmap are dimension of the mapped image
% in log-polar coordinates
% indvec contains the coordinates of the cartesian representation
% ordered so they map into N sequentially
N = zeros(ylcmap,xlcmap);

T = M(:);
N(:) = T(indvec);