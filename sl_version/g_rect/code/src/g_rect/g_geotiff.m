function [] = g_geotiff(LON,LAT,dx,lon_min,lon_max,lat_min,lat_max)
%
% This function creates geotiff images given the longitudes (LON)
% and latitudes (LAT) of every pixels of the associated jpeg images found 
% in the current folder. The matrices LON and LAT typically come from the 
% g_rect package.
%
% The geotiff images are constructed by interpolating on a regular grid of
% size dx (in m) the irregularly-spaced pixel intensities defined by the  
% LON-LAT pair. 
%
% INPUT PARAMETERS:
%
%     LON:     A matrix of size identical to the associated images in the current 
%              folder that gives the longitude of every pixel of those images. 
%              This matrix would typically come from the g_rect package.
%
%     LAT:     Same as LON but for the latitude.
%
%     dx:      The grid size (in m) of the regularly-spaced interpolated 
%              geotif image
%
%     lon_min: The longitude of the southwest corner of the desired 
%              geotif image.
%
%     lon_max: The longitude of the northeastcorner of the desired 
%              geotif image.
%
%     lat_min: The latitude of the southwest corner of the desired 
%              geotif image.
%
%     lat_max: The latitude of the northeastcorner of the desired 
%              geotif image.
%
% OUTPUT:
%
%     This function writes geotiff images that have the same name as the
%     jpeg images but with the extension .tif 
%
% LAST REVISION: 5 May 2020
%
% AUTHOR: 
%     - Daniel Bourgault (daniel_bourgault@uqar.ca) 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Construct the vectors 'lon' and 'lat' that define the interpolating 
% grid of constant resolution dx (in m)
lat0 = (lat_min + lat_max)/2;
dlat = dx/(1852*60);
dlon = dlat/cosd(lat0);
lon  = [lon_min:dlon:lon_max];
lat  = [lat_min:dlat:lat_max];

% Find the indices of only the finite values in the matrix LON 
% so that the interpolation is only done on finite values and does 
% not spend time interpolating NaNs. 
ifinite = find(isfinite(LON) == 1);

% Find all .jpg images in the current folder
img_fname = dir('*.jpg');
N_img     = length(img_fname);

% Loop over all images
for i = 1:N_img
    
    img = imread(img_fname(i).name);
    
    % Convert to gray scale
    [m n p] = size(img);
    if p > 1
        img = rgb2gray(img);
    end
    img = double(img);
    img = img';
    
    % Interpolate on the regular grid defined above by the vector 
    % lon and lat
    img_interp = griddata(LON(ifinite),LAT(ifinite),img(ifinite),lon,lat');
    
    % Convert real numbers to unsigned integers 
    img_interp = uint8(img_interp);

    % Write the geotiff file
    geotif_img_fname = [img_fname(i).name(1:end-3),'tif']
    bbox =  [lon_min, lat_min; lon_max, lat_max];
    geotiffwrite(geotif_img_fname, bbox, flipud(img_interp),8);

end