function g_stabilize(img_ref_fname,varargin)
% This function and its sub-functions stabilize all images found in the 
% working folder against a reference image. The stabilized files
% contain the datetime values stored in the 'DateTime' or the 'Comment'
% field of the unstabilized images.
% 
% Input: 
%   img_ref_fname: The complete image name, with extension (and path if 
%                  necessary), of the reference image in the current 
%                  directory.
%
%   Optional parameters:
%       L_level_Gaussian:   Size of the L-level Gaussian pyramid [Default: 4]
%       roi_file:           Name of the file with roi information [Default: 'roi.mat']
%       fname_suffix:       Suffix to add to the stabilized images [Default: '_stable']
%       output_folder:      Name of the output folder [Default: 'stable']
%       equalize:           Use image equalization over the roi region [Default: 0 (false)]
%       use_img_grad:       Perform the stabilization using the gradient of the image [Default: 0 (false)]
%       auto:               If true, overrides any interaction with the user 
%                           (for use in scripts) [Default: 0 (false)] 
%
% Output:
%   All stabilized images are rewritten as image files in the subfolder 
%   /stable (by default or other name is specified).
%
% Examples:
%   Example 1: Using all default parameters
%   >> g_stabilize('IMG_4018.jpg');
%
%   Example 2: Using a different L level Gaussian than the default value (4)
%   >> g_stabilize('IMG_4018.jpg','L_level_Gaussian',6);
%
%   Example 3: Using a different L level Gaussian than the default value (4)
%              and a different suffix than the default (_stable) and
%              without any image equalization
%   >> g_stabilize('IMG_4018.jpg','L_level_Gaussian',6,'fname_suffix','_very_stable','equalize',false);
%

%%
p = inputParser;

% Default values
default_L_level_Gaussian = 4;
default_roi_file         = 'roi.mat';
default_fname_suffix     = '_stable';
default_output_folder    = 'stable';
default_equalize         = false;
default_use_img_grad     = false;
default_auto             = false;

addRequired(p,'img_ref_fname',@ischar);
addParameter(p,'L_level_Gaussian',default_L_level_Gaussian,@isnumeric);
addParameter(p,'roi_file',default_roi_file,@ischar);
addParameter(p,'fname_suffix',default_fname_suffix,@ischar);
addParameter(p,'output_folder',default_output_folder,@ischar);
addParameter(p,'equalize',default_equalize,@islogical);
addParameter(p,'use_img_grad',default_use_img_grad,@islogical);
addParameter(p,'auto',default_auto,@islogical);

parse(p,img_ref_fname,varargin{:})

img_ref_fname = p.Results.img_ref_fname;
L             = p.Results.L_level_Gaussian;
roi_file      = p.Results.roi_file;
fname_suffix  = p.Results.fname_suffix;
output_folder = p.Results.output_folder;
equalize      = p.Results.equalize;
use_img_grad  = p.Results.use_img_grad;
auto          = p.Results.auto;

disp(['   ']);
disp(['   -----------------------------------------------------------------------']);
disp(['   IMAGE STABILIZATION PARAMETERS']);
disp(['     Filename of the reference image:              ',img_ref_fname]);
disp(['     L-level Gaussian:                             ',num2str(L)]);
disp(['     Name of the ROI filename:                     ',roi_file]);
disp(['     Suffix of stabilized filenames:               ',fname_suffix]);
disp(['     Output folder:                                ',output_folder]);
disp(['     Equalize (1) or not (0) the roi region:       ',num2str(equalize)]);
disp(['     Use (1) or not (0) the gradient of the image: ',num2str(use_img_grad)]);
disp(['   -----------------------------------------------------------------------']);

%% Equalization parameters
% Parameters for equalization. See help clahs for details.
% This may not be needed for most applications but may help in some cases 
% where the lighting conditions changes a lot.
% Need to play with it if problems. 
if equalize
    nry = 8;
    nrx = 8;
end

%%

% Extract the path and extension of the reference image
[pathstr,name,ext] = fileparts(img_ref_fname);


%% Load the Region of interest (roi) file
disp(['   ']);
display('   Loading the file containing the region of interest (roi)...');
if length(pathstr) == 0  % Images are in the current folder
    load(roi_file);
else
    load([pathstr,'/',roi_file]);
end

% Read the reference image
im2 = imread(img_ref_fname);

% Convert into gray scale if not already a B/W image
if size(im2,3) ~= 1
    im2_BW = g_rgb2gray(im2);
else
    im2_BW = im2;
end

im2_BW_cooked = im2_BW;
clear im2;

% May equalize with this equalizer. Careful this doesn't always work well
% and may compromise the stabilization. Use with care. 
if equalize
    im2_BW_cooked = clahs(im2_BW_cooked,nry,nrx);
end

im2_BW        = double(im2_BW);
im2_BW_cooked = double(im2_BW_cooked);

% Remove mean and divide by the standard deviation.
% This generally help the algorithm to compare images that have different
% light conditions
%inorm    = find(roi > 0);
%im2_BW_cooked = (im2_BW_cooked - nanmean(im2_BW_cooked(inorm)))./nanstd(im2_BW_cooked(inorm));

if use_img_grad
    % Take the norm of the gradient of the image. This may help the
    % stabilization algorithm but not always. Use this option with care. 
    [im2x, im2y]  = gradient(im2_BW_cooked);
    im2_BW_cooked = sqrt(im2x.^2 + im2y.^2);    
end

frames(2).im = im2_BW_cooked;

%% Some figures to make sure everything is ok
figure(1);
imagesc(im2_BW);
colormap(gray);
title('Reference image in B/W');

figure(2);
imagesc(im2_BW_cooked);
colormap(gray);
title('Reference image manipulated (if so)');

figure(3);
% Produce a mask over non-ROI region and plot it
iNaN = find(roi == 0);
roi_with_NaN = roi;
roi_with_NaN(iNaN) = NaN;
imagesc(im2_BW_cooked.*roi_with_NaN);
colormap(gray);
title('Reference image manipulated with mask over non-ROI');

%if ~auto
%    disp([' '])
%    answer = input('   Happy with roi and parameters (y/n)? ','s');
%    if answer == 'n'
%        return
%    end
%end

display(['    ']);

%% Create the folder where to write the stable images
if length(pathstr) == 0  % Images are in the current folder
    [status,message,messageid] = mkdir(output_folder);
    save([output_folder,'/g_stabilize_info.mat'],'p','roi');
else
    [status,message,messageid] = mkdir([pathstr,'/',output_folder]);
    save([pathstr,'/',output_folder,'/g_stabilize_info.mat'],'p','roi');
end

%% Read all filemanes in the current directory with the same extension as the ref img
if length(pathstr) == 0  % Images are in the current folder
    all_img = dir(['*',ext]);
else
    all_img = dir([pathstr,'/','*',ext]);
end

% Number of images to proceed
N = length(all_img);

time_per_img = 0;

for i = 1:N
    
    time_rem = (N-i+1)*time_per_img;
    
    total = tic;
    
    if length(pathstr) == 0
        im1     = imread(all_img(i).name);
        im_info = imfinfo(all_img(i).name);
    else
        im1     = imread([pathstr,'/',all_img(i).name]);
        im_info = imfinfo([pathstr,'/',all_img(i).name]);
    end
        
    if i == 1
        display(['   Processing image: ',all_img(i).name]);
        display(['   Time remaining:   Yet undetermined. Please wait until next image.']);
        display(['  ']);
    else
        display(['   Processing image: ',all_img(i).name]);
        display(['   Time remaining:   ',datestr(time_rem/86400,'HH:MM:SS')]);
        display(['  ']);
    end

    % Convert into gray scale if not already a B/W image
    if size(im1,3) ~= 1
        im1_BW = g_rgb2gray(im1);
    else
        im1_BW = im1;
    end
    
    im1_BW_cooked = im1_BW;
        
    % May equalize with this equalizer.
    if equalize
        im1_BW_cooked = clahs(im1_BW_cooked,nry,nrx);
    end
    
    im1_BW_cooked = double(im1_BW_cooked);    
    im1_BW        = double(im1_BW);

    % Normalize the image over the ROI.
    %im1_BW_cooked     = (im1_BW_cooked - nanmean(im1_BW_cooked(inorm)))./nanstd(im1_BW_cooked(inorm));
    
    if use_img_grad
        [im1x, im1y]  = gradient(im1_BW_cooked);
        im1_BW_cooked = sqrt(im1x.^2 + im1y.^2);
    end
    
    frames(1).im = im1_BW_cooked;
        
    [motion,stable] = g_videostabilize(frames,roi,L);
    
    % Warp the original image and not the image that has been manipulated
    % for the stabilization.
    Acum        = [1 0 ; 0 1];
    Tcum        = [0 ; 0];
    [Acum,Tcum] = g_accumulatewarp(Acum, Tcum, motion(1).A, motion(1).T);
    
    RGB = true;
    if RGB
        for j = 1:3
            im1_stable(:,:,j) = g_warp(double(im1(:,:,j)), Acum, Tcum);
        end
        % Uncomment if wanna use the previous stabilized image as the reference image  
        %frames(2).im = (im1_stable(:,:,1) + im1_stable(:,:,2) + im1_stable(:,:,3))/3;
    else
        im1_stable   = g_warp(im1_BW, Acum, Tcum);
        % Uncomment if wanna use the previous stabilized image as the reference image  
        %frames(2).im = im1_stable;
    end

    if isfield(im_info,'DateTime')
        datetime = im_info.DateTime;
    elseif isfield(im_info,'Comment')
        datetime = im_info.Comment;
    else
        datetime = '';
    end
    
    if length(pathstr) == 0
        stable_img_fname = [output_folder,'/',all_img(i).name(1:end-4)];
    else
        stable_img_fname = [pathstr,output_folder,'/',all_img(i).name(1:end-4)];
    end
    
    imwrite(uint8(im1_stable),[stable_img_fname fname_suffix ext],...
           'Quality',100,'Comment',datetime);
    
    time_per_img = toc(total);
    
end