function [S] = blend(A,B,R)
%BLEND blends two images across their transistion zone
%   S = BLEND(A,B,R) blends the two images A and B 
%   according to the mask R.  R is an array of the same
%   size as A and B and contains 1's at indices corresponding
%   to regions of A to be blended into B.
%
%   example:
%
%   A = imread('rice.tif');
%   B = uint8(double(A)-40); % darken image
%   C = A;
%   C(:,end/2:end) = B(:,end/2:end); % create composite image
%   figure; imshow(C); title('Unblended');
%   R = zeros(size(A));
%   R(:,1:end/2-1) = 1;
%   D = blend(A,B,R);
%   figure; imshow(D); title('Blended');

type = class(A);
A = double(A);
B = double(B);
R = double(R);
N = numlevels(A);
%==================================
% construct the laplacian pyramid
% for each image
%==================================
LA = pyramid(A,N);
LB = pyramid(B,N);

%==================================
% construct the gaussian pyramid
% for the mask R
%==================================
GR = cell(N,1);
GR{1} = R;
for ii = 2:N
    GR{ii} = reduce(GR{ii-1});
end

%==================================
% construct the laplacian pyramid
% for the splined image S
%==================================
LS = cell(N,1);
for ii = 1:N
    LS{ii} = GR{ii}.*LA{ii} + (1-GR{ii}).*LB{ii};
end

%==================================
% reconstruct the splined image S
% from the laplacian pyramid LS
%==================================
S = deflate(LS);

%==================================
% convert S to the same class type
% as the input images
%==================================
cmd = sprintf('S = %s(S);',type);
eval(cmd);


function [N] = numlevels(A);
% returns the ideal number of levels used in
% generating the laplacian pyramid
% for images of size (Mr*2^N + 1) by (Mc*2^N + 1)
% where Mr,Mc are integers, then the pyramid should
% contains N+1 levels.
[rowA colA] = size(A); 
N = min(floor(log2(rowA)),floor(log2(colA)));