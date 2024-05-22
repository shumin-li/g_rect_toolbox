function g_roi2(imgFname)
% G_ROI is a function to determine regions of interest in an image.
%
% This function allows the user to define a series of polygons 
% on an image in order to define regions of interest (roi) for 
% image stabilization. The result is a 2D matrix roi with 1s and 0s.
% Just follow the instructions.
%
% Input:  imgFname: the image filename
% Output: The 2D matrix roi written to filename roi.mat
%
%  ** There is tips to modifie and adjuste the roi before saving it in the
%  help menu of the impoly function.
%   Example : Hold the button A and click on the polygon border to add
%   points.
%
% Author: Daniel Bourgault - 2011
%
% Updated : - 11/05/19 - Show the lines while creating the polygon.
% Updated : - 08/08/19 - Enable modification of the polygon before saving.
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Reading reference images
im = imread(imgFname);
[m,n,~] = size(im);
roi(1:m,1:n) = 0; % Create ROI matrix

%% Generating Region of Interest
imagesc(im)
hold on
colormap(gray);

continue_draw = 'y';
while continue_draw == 'y'
    % Instructions
    fprintf('  Make a polygon with left click on the mouse\n') 
    fprintf('  Right click to link the last and first point\n')
    fprintf('  Double click on the polygon when you are done arranging points\n')
    fprintf('  You will have the option to make more polygons when done with this one\n')
    % Drawing
    h=impoly;
    wait(h);
    Mask = createMask(h);   
    roi = roi+Mask;
    continue_draw = input('Draw another polygon (y/n) ? ','s');
end
hold off

ij = roi > 1;
roi(ij) = 1;

% Final figure
figure(2)
imagesc(roi)

save([imgFname(1:end-4),'_roi.mat'],'roi','imgFname');