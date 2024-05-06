function I = g_rgb2gray(X)
%G_RGB2GRAY Convert RGB image or colormap to grayscale.
%   G_RGB2GRAY converts RGB images to grayscale by eliminating the
%   hue and saturation information while retaining the
%   luminance.
%
%   If RGB2GRAY exists in the Matlab path, it overrides this function and
%   uses the one from the toolbox instead.
%
%   I = G_RGB2GRAY(RGB) converts the truecolor image RGB to the
%   grayscale intensity image I.
%
%   NEWMAP = G_RGB2GRAY(MAP) returns a grayscale colormap
%   equivalent to MAP.
%
%   Class Support
%   -------------  
%   If the input is an RGB image, it can be uint8, uint16, double, or
%   single. The output image I has the same class as the input image. If the
%   input is a colormap, the input and output colormaps are both of class
%   double.
%
%   Example
%   -------
%   I = imread('board.tif');
%   J = rgb2gray(I);
%   figure, imshow(I), figure, imshow(J);
%
%   [X,map] = imread('trees.tif');
%   gmap = rgb2gray(map);
%   figure, imshow(X,map), figure, imshow(X,gmap);
%
%   See also IND2GRAY, NTSC2RGB, RGB2IND, RGB2NTSC, MAT2GRAY.

%   Original file: Copyright 1992-2013 The MathWorks, Inc. 
%   And some changes by me.

if exist('rgb2gray','file')
    I = rgb2gray(X);
else
X        = parse_inputs(X);
origSize = size(X);

% Determine if input includes a 3-D array 
threeD = (ndims(X)==3);

% Calculate transformation matrix
T    = inv([1.0 0.956 0.621; 1.0 -0.272 -0.647; 1.0 -1.106 1.703]);
coef = T(1,:);

if threeD
  %RGB
  
  % Do transformation
  if isa(X, 'double') || isa(X, 'single')

    % Shape input matrix so that it is a n x 3 array and initialize output matrix  
    X          = reshape(X(:),origSize(1)*origSize(2),3);
    sizeOutput = [origSize(1), origSize(2)];
    I = X * coef';
    I = min(max(I,0),1);

    %Make sure that the output matrix has the right size
    I = reshape(I,sizeOutput);
    
  elseif isa(X,'uint8')
    % Transforms to double to do the transformations as some functions are
    % not available without the Image Processing toolbox.
    I = uint8(g_rgb2gray(double(X)/255)*255);
  elseif isa(X,'uint16')
    I = uint16(g_rgb2gray(double(X)/255)*255);
  end

else
  I = X * coef';
  I = min(max(I,0),1);
  I = [I,I,I];
end

end
%%%
%Parse Inputs
%%%
function X = parse_inputs(X)


if ismatrix(X)
  if (size(X,2) ~=3 || size(X,1) < 1)
    error(' images:rgb2gray:invalidSizeForColormap')
  end
  if ~isa(X,'double')
    error(' images:rgb2gray:notAValidColormap')
  end
elseif (ndims(X)==3)
    if ((size(X,3) ~= 3))
      error(' images:rgb2gray:invalidInputSizeRGB')
    end
else
  error(' images:rgb2gray:invalidInputSize')
end
  

%no logical arrays
if islogical(X)
  error(' images:rgb2gray:invalidType')
end
