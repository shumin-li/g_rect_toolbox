function [L] = pyramid(G0,N,varargin);
%PYRAMID generates the laplacian image pyramid
%   L = PYRAMID(G0,N) takes as arguments the original
%   image G0 and the number of levels N.  It then computes
%   the corresponding N level pyramid L.  L is a N-by-1
%   cell array with each cell containing the Kth pyramid
%   level.

if nargin == 2
    L = cell(N,1);
else
    L = varargin{1};
end

if N == 1
    L{end} = G0;
else
    G1 = reduce(G0);
    L{length(L)-N+1} = G0 - expand(G1,size(G0));
    L = pyramid(G1,N-1,L);
end