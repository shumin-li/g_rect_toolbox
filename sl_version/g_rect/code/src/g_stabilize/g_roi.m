function g_roi(imgFname);

% G_ROI is a function to determine regions of interest in an image.
%
% This function allows the user to define a series of polygons 
% on an image in order to define regions of interest (roi) for 
% image stabilization. The result is a 2D matrix roi with 1s and 0s.
% Just follow ths instructions.
%
% Input:  imgFname: the image filename
% Output: The 2D matrix roi written to filename roi.mat
%
% Author: Daniel Bourgault - 2011
%
%

im = imread(imgFname);
imagesc(im);
colormap(gray);
hold on;

[m n p] = size(im);

roi(1:m,1:n) = 0.0;

I = repmat([1:m]',1,n);
J = repmat([1:n],m,1);

answer='y';
while answer=='y'

  display(' ');
  input('  Position the image as you wish before defining a polygon. Press ENTER when ready.');
  
  display(' ');
  display('  Make a polygon with the mouse. Press ENTER when done with this polygon.')
  display('  You will have the option to make more polygons when done with this one.')
  
  [px py] = ginput;

  px(end+1) = px(1);
  py(end+1) = py(1);
  
  plot(px,py,'r');
  
  roiTmp = inpolygon(I,J,py,px);
  
  display(' ');
  answer = input('  Enter another polygon (y/n)? ','s');
  
  roi = roi + roiTmp;
  
end

ij = find(roi > 1);
roi(ij) = 1;

figure(2);
imagesc(roi);

save([imgFname(1:end-4),'_roi.mat'],'roi','imgFname');