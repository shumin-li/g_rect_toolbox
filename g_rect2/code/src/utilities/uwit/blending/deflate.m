function [I] = deflate(L);
% DEFLATE produces an image array from a laplacian pyramid
%   I = DEFLATE(L) produces a single output array I, which
%   is the result of expanding and adding the length(L) levels
%   of the laplacian pyramid L.

for ii = length(L):-1:2
    L{ii-1} = L{ii-1} + expand(L{ii},size(L{ii-1}));
end
I = L{1};