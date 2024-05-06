function dummy = DNG2jpg(DNG_filename)

% Based off code found in Processing RAW Images in MATLAB by Rob Sumner
% (May 19, 2014) which can be found here:
% https://rcsumner.net/raw_guide/RAWguide.pdf
% Used to convert DNG images to JPGs without additional post-processing

% Original code by Rob Sumner debugged and augmented by Daniel Bourgault
% ISMER, 2019.

%clear all;

%% Turn off annoying warnings
warning off MATLAB:tifflib:TIFFReadDirectory:libraryWarning
warning off MATLAB:imagesci:tifftagsread:badTagValueDivisionByZero
warning off MATLAB:imagesci:tiffmexutils:libtiffWarning


%% DNG Image Loading
%[fileName,pathName] = uigetfile('*.DNG','Select the DNG image');
%cd(pathName);

t = Tiff(DNG_filename,'r');

offsets = getTag(t,'SubIFD');
setSubDirectory(t,offsets(1));

raw = read(t);
close(t);

meta_info = imfinfo(DNG_filename);

x_origin = meta_info.SubIFDs{1}.ActiveArea(2) + 1;
width    = meta_info.SubIFDs{1}.Width;
y_origin = meta_info.SubIFDs{1}.ActiveArea(1) + 1;
height   = meta_info.SubIFDs{1}.Height;

raw = double(raw(y_origin:y_origin+height-1,x_origin:x_origin+width-1));

%% Linearizing
black      = meta_info.SubIFDs{1}.BlackLevel(1);
saturation = meta_info.SubIFDs{1}.WhiteLevel;
lin_bayer  = (raw - black)/(saturation - black);
lin_bayer  = max(0,min(lin_bayer,1));


%% White balancing
wb_multipliers = (meta_info.AsShotNeutral).^(-1);
wb_multipliers = wb_multipliers/wb_multipliers(2);
mask           = wbmask(size(lin_bayer,1),size(lin_bayer,2),wb_multipliers,'rggb');
balanced_bayer = lin_bayer.*mask;

%% De-mosaicing
%temp    = uint16(lin_bayer/max(lin_bayer(:))*2^16);
temp    = uint16(balanced_bayer/max(balanced_bayer(:))*2^16);
lin_rgb = double(demosaic(temp,'rggb'))/2^16;

%% Color Space Conversion
xyz2cam  = [meta_info.ColorMatrix2(1),meta_info.ColorMatrix2(2),meta_info.ColorMatrix2(3);...
           meta_info.ColorMatrix2(4),meta_info.ColorMatrix2(5),meta_info.ColorMatrix2(6);...
           meta_info.ColorMatrix2(7),meta_info.ColorMatrix2(8),meta_info.ColorMatrix2(9)]; % color correction matrix
rgb2xyz  = [0.4124564,0.3575761,0.1804375;...
           0.2126729,0.7151522,0.0721750;...
           0.0193339,0.1191920,0.9503041];        % sRGB to XYZ
rgb2cam  = xyz2cam*rgb2xyz;                     % Assuming previously defined matrices
rgb2cam  = rgb2cam./repmat(sum(rgb2cam,2),1,3); % Normalize rows to 1
cam2rgb  = rgb2cam^-1;
lin_srgb = apply_cmatrix(lin_rgb, cam2rgb);
lin_srgb = max(0,min(lin_srgb,1)); % Always keep image clipped b/w 0-1

%% Brightness and gamma correction
grayim      = rgb2gray(lin_srgb);
grayscale   = 0.25/mean(grayim(:));
bright_srgb = min(1,lin_srgb*grayscale);
nl_srgb = bright_srgb.^(1/2.2);

%% File Saving
newFileName = strcat(DNG_filename(1,1:end-3),'jpg');
imwrite(nl_srgb,newFileName,'jpg','Quality',100)

