function [varargout] = rstreg(I1,I2,varargin)
%RSTREG Registers an image pair for rotation, scale, and
%       and tranlation using Fourier transform properties.
%
%   [SCALE,THETA,TRAN] = RSTREG(I1,I2) registers a pair of images
%   I1,I2 using Fourier based methods which can account for images
%   which are related through a scaling, rotation, and translation.
%   The parameters SCALE,THETA, and TRAN are all measured relative
%   to I1's coordinate frame.  TRAN is a 2x1 vector of translations
%   [tu tv]'.
%
%   [SCALE,THETA,TRAN,J] = RSTREG(I1,I2) and
%   [J] = RSTREG{I1,I2) optionally return the registered
%   output image I2 in I1's coordinate frame.
%
%   RSTREG(I1,I2) without any output argument assignments generates
%   output figures only.
%
%   The I1,I2 pair can be followed by parameter/value pairs to 
%   specify additional arguments.  The following parameter/value
%   arguments may be specified (not case sensitive):
%   Paramter/Value       Comment
%   -------------------------------------------------------
%   'F1DIM'              # of samples of FFT in column direction
%   'F2DIM'              # of samples of FFT in row direction
%   'RDIM'               # of samples in log-polar radial coordinate
%   'TDIM'               # of samples in log-polar theta coordinate
%   'CWIN'               size of cosine window support
%   'THRESH'             controls oversampling of pixels with small
%                        radial component, default 600
%   'SHOW_FIGS'          0 produces no figures
%                        1 produces only registered output image figures
%                        2 produces lots of figures
%
%EXAMPLE1
%
%   I1 = double(rgb2gray(imread('westconcordaerial.png')));
%   [rdim,cdim] = size(I1);
%   I2 = imresize(I1,1.2,'bicubic');
%   I2 = imrotate(I2,25.0,'bicubic','crop');
%   I2 = I2(1:rdim,1:cdim);
%   rstreg(I1,I2);
%
%EXAMPLE2
%
%   I1 = double(imread('images/ESC.0565.tif'));
%   I2 = double(imread('images/ESC.0564.tif'));
%   rstreg(I1,I2);

%HISTORY
%DATE       WHO             COMMENT
%--------   -------------   -----------------------------
%05/2002    Ryan Eustice    Streamlined and speed up original code.
%05/2000    Oscar Pizarro   Originally created and implemented
%                           all functionality of algorithm.


show_figs = 0;
%===============================================
% CHECK FOR OPTIONAL ARGUMENTS
%===============================================
NARGIN = nargin;
if NARGIN < 2
    error('Invalid number of arguments');
elseif NARGIN > 2
    done = 0;
    ii = 1;
    while ~done
        switch lower(varargin{ii})
        case 'f1dim';     f1dim = varargin{ii+1}; ii=ii+2;
        case 'f2dim';     f2dim = varargin{ii+1}; ii=ii+2;
        case 'rdim';      rdim = varargin{ii+1}; ii=ii+2;
        case 'tdim';      tdim = varargin{ii+1}; ii=ii+2;
        case 'cwin';      cwin = varargin{ii+1}; ii=ii+2;        
        case 'thresh';    thresh = varargin{ii+1}; ii=ii+2;            
        case 'show_figs'; show_figs = varargin{ii+1}; ii=ii+2;            
        otherwise
            msg = sprintf('Unknown argument given');
            error(msg);
        end
        if ii >= length(varargin); done = 1; end
    end
end

NARGOUT = nargout;
if NARGOUT == 0;
    show_figs = 2;
end


%====================================
% CREATE COSINE WINDOW THAT BRINGS
% INTENSITIES TO ZERO ON IMAGE BORDERS
%====================================
[rowdim,coldim] = size(I1);
if ~exist('cwin','var')
    %set default size of support
    cos_support = 80;
end
cwin = coswin(rowdim,coldim,cos_support); 


%==============================
% I1 CONTROL IMAGE
%==============================
if show_figs >= 1
    figure(1)
    imagesc(I1); colormap gray; axis image; grid on; truesize;
    title('Control image');
end

I1prime = double(I1);
I1prime = I1prime - mean(I1prime(:)); %remove DC mean intensity
I1prime = I1prime.*cwin; %smooth freq at border of image
if show_figs >= 2
    figure(2)
    imagesc(I1prime); colormap gray; axis image; grid on; truesize;
    title('Windowed Control image');
end

%===============================
% I2 INPUT IMAGE
%===============================
if show_figs >= 1
    figure(3)
    imagesc(I2); colormap gray; axis image; grid on; truesize;
    title('Input image');
end

I2prime = double(I2);
I2prime = I2prime - mean(I2prime(:)); %remove DC mean intensity
I2prime = I2prime.*cwin; %smooth freq at border of image
if show_figs >= 2
    figure(4)
    imagesc(I2prime); colormap gray; axis image; grid on; truesize;
    title('Windowed Input image');
end


%==================================
% HIGH FREQ EMPHASIS FILTER
%==================================
fsize = 41;  %assume odd filter support
if ~exist('sigma','var')
    %set default
    sigma = 1.5; %std dev in pixels
end

%design filter's spatial impulse response
h = fspecial('log',fsize,sigma);


%====================================
% APPLY FILTER TO IMAGES
%====================================
%(f1dim,f2dim) are dimensions of FFT's
%which control zero padding and aliasing
%set defaults to be of equal dimension
if ~exist('f1dim')
    f1dim = max(rowdim,coldim);  %f1dim >= coldim
end
if ~exist('f2dim')
    f2dim = max(rowdim,coldim);  %f2dim >= rowdim
end

%phase correction to translate filter to the origin
k1 = [0:f2dim-1]';
k2 = [0:f1dim-1];
phasecorrection = ...
    (exp(j*k1*2*pi/(f2dim)*(fsize-1)/2)*exp(j*k2*2*pi/f1dim*(fsize-1)/2));

%apply laplacian of gaussian filter to images 
%in the frequency domain with the correct phase
hF1 = fft2(I1prime,f2dim,f1dim);
hF2 = fft2(I2prime,f2dim,f1dim);
fH  = fft2(h,f2dim,f1dim);
hF1 = hF1.*fH.*phasecorrection;
hF2 = hF2.*fH.*phasecorrection;


%=====================================
% MAGNITUDE OF FT OF FILTERED IMAGES
%=====================================
M1 = (fftshift(abs(hF1)));
M2 = (fftshift(abs(hF2)));
if show_figs >= 2
    figure(5);
    imagesc(M1); axis image; grid on; 
    title('Magnitude of spectrum. Filtered Control image.');
    crange = caxis;
    
    figure(6); 
    imagesc(M2,crange); axis image; grid on;
    title('Magnitude of spectrum. Filtered Input image.');
end


%=======================================
% INVERSE TRANSFORM SPECTRA TO GET
% FILTERED IMAGES IN SPATIAL DOMAIN
%=======================================
if NARGOUT == 0 | show_figs == 2
    hI1 = (real(ifft2(hF1)));
    hI1 = hI1(1:rowdim,1:coldim);
    hI2 = (real(ifft2(hF2)));
    hI2 = hI2(1:rowdim,1:coldim);
end
if show_figs >= 2    
    figure(7);
    imagesc(hI1); axis image; grid on; truesize;
    title('Filtered Control image.');
    crange = caxis;
    
    figure(8);
    imagesc(hI2,crange); axis image; grid on; truesize;
    title('Filtered Input image.');
end

%conserve memory and clear intermediate variables
clear I1prime I2prime H phasecorrection;


%============================================
% CREATE LOG-POLAR CONVERSION LOOK-UP-TABLE
% IF IT DOESN'T ALREADY EXIST
%============================================
tol = 0.001;
Hmin = 0.03;

%find radius of bandpass annulus of
%highpass emphasis filter by looking in
%upper left quadrant of fft 
%(fft calculated w/o correction for fftshift)
wdim1 = find(Hmin-tol < abs(fH(1,1:f1dim/2)) & ...
             Hmin+tol > abs(fH(1,1:f1dim/2)));
wdim2 = find(Hmin-tol < abs(fH(1:f2dim/2,1)) & ...
             Hmin+tol > abs(fH(1:f2dim/2,1)));        
   
%keep the maximum radial dimension
wdim1 = max(wdim1);
wdim2 = max(wdim2);

%choose the minimum of the two frequency axis 
%components as the size of the frequency annulus
%to map into log-polar coordinates
wdim = min(wdim1,wdim2);


%(rdim,tdim) are dimensions of log-polar
%mapped image representing the number of 
%samples in the (log(rho),theta) axes repectively
%set defaults to be <= min(f1dim,f2dim)
%frequency resolution in log-polar space
%cannot be any better than resolution in
%cartesian domain
if ~exist('rdim')
    rdim = min(f1dim,f2dim);  %# of samples in log(rho) axis
end
if ~exist('tdim')
    tdim = min(f1dim,f2dim);  %# of samples in theta axis
end

%check to see if a previously cached LUT exists
%otherwise create it
lutfile = strcat(tempdir,'lut.mat');
if exist(lutfile,'file')
    load(lutfile);
end
createLUT = 0;
if exist('lut','var')
    if lut.f1dim ~= f1dim | lut.f2dim ~= f2dim
        createLUT = 1;
    elseif lut.tdim ~= tdim | lut.rdim ~= rdim
        createLUT = 1;
    elseif exist('thresh','var');
        if lut.thresh ~= thresh
            createLUT = 1;
        end
    end
else
    createLUT = 1;
end 
if createLUT
    if exist('thresh','var');
        fprintf('Creating LUT with thresh = %g',thresh);
    else
        fprintf('Creating LUT ...');
    end
    if exist('thresh','var')
        lut = lplut(f1dim,f2dim,wdim,rdim,tdim,thresh);        
    else
        lut = lplut(f1dim,f2dim,wdim,rdim,tdim);
    end
    save(strcat(tempdir,'lut.mat'),'lut');
    fprintf(' done\n\n');
else
    fprintf('Using cached LUT with thresh = %g ...\n\n',lut.thresh);    
end
    

%==========================================
% MAP MAGNITUDE SPECTRUMS TO LOG-POLAR SPACE
%==========================================
N1 = (lutmapper(M1,lut.w2lcmap,lut.w1lcmap,lut.indvec));
N2 = (lutmapper(M2,lut.w2lcmap,lut.w1lcmap,lut.indvec));
[tdim,rdim] = size(N1);
if show_figs >= 2
    figure(9);
    imagesc([],[0:tdim-1]/lut.vscale,N1); grid on; 
    title('Log-polar Magnitude of Spectrum. Control Image.');
    xlabel('samples of log(\rho), [\rho measured in pixels]');
    ylabel('\theta [deg]')
    crange = caxis;
    
    figure(10);
    imagesc([],[0:tdim-1]/lut.vscale,(N2),crange); grid on; 
    title('Log-polar Magnitude of Spectrum. Input Image.');
    xlabel('samples of log(\rho), [\rho measured in pixels]');
    ylabel('\theta [deg]')
end


%===========================================
% CALCULATE SCALE AND THETA PARAMETERS VIA
% PHASE CORRELATION TECHNIQUE
%  -->circular convolution in the theta direction
%  -->linear convolution in the radius direction
%===========================================
%Q1 & Q2 are the transforms of N1 & N2, 
%the log-polar representations of M1 & M2
Q1 = fft2(N1,tdim,2*rdim-1);
Q2 = fft2(N2,tdim,2*rdim-1);

%conserve memory and clear intermediate variables
clear N1 N2 M1 M2;

%calculate the cross-power spectrum
CPS = Q1.*conj(Q2);
CPS = CPS./abs(CPS);

%inverse transform cross-power spectrum
%to get an impulse
peakM = real(fftshift(ifft2(CPS)));

%conserve memory and clear intermediate variables
clear Q1 Q2 CPS;

%find coordinates of impulse to recover
%scale and theta parameters
[yM,xM] = size(peakM);
maxval  = max(peakM(:));
[iind,jind] = find(peakM == maxval);

% refer to image coordinates
jmax = jind - (xM/2) - 1;
imax = iind - (yM/2) - 1;


%============================================
% CALCULATE SCLAE AND ROTATION USING
% MAPPING PARAMETERS
%============================================
scale = lut.base^(jmax/lut.hscale);
theta = -imax/lut.vscale; %multiply by -1 to conform to
                          %convention of theta defined
                          %positive counter-clockwise
                          

%=============================================                          
% DETERMINE TRANSLATIONAL OFFSET AND 
% RESOLVE 180 DEGREE AMBIGUITY IN THETA
%=============================================
%transform filtered input image according to theta and scale
hJ2 = imrotate(hI2,-theta,'bilinear','crop');
hJ2 = imresize(hJ2,1/scale,'bilinear');
hJ2flip = flipud(fliplr(hJ2));

% find translation using phase correlation technique
[tu1,tv1,peakcorr1] = find_xlate2(hI1,hJ2);
[tu2,tv2,peakcorr2] = find_xlate2(hI1,hJ2flip);
if peakcorr1 > peakcorr2
  tu = tu1;
  tv = tv1;
  peakcorr = peakcorr1;
else
  tu = tu2;
  tv = tv2;
  peakcorr = peakcorr2;
  theta = theta+180;
end
    
%conserve memory and clear intermediate variables
clear tu1 tv1 peakcorr1 tu2 tv2 peakcorr2 hI2 hJ2flip;

%display results
fprintf('scale = %g, res = %g, rdim = %g samples ...\n', ...
         scale,lut.base^(1/lut.hscale)-1,rdim);
fprintf('theta = %g degrees, res = %g, tdim = %g samples ...\n', ...
         theta,1/lut.vscale,tdim);
fprintf('translation (x,y) = (%g,%g) ...\n',tu,tv);


%=============================================
% CREATE A MATLAB TFORM STRUCTURE WHICH
% CAN BE USED BY IMTRANSFORM TO WARP
% THE INPUT IMAGE
%=============================================
%calculate a pre-multiply homography H12 which
%rotates and scales I2 towards I1
D2R = pi/180;
H12 = eye(3);
H12(1:2,1:2) = (1/scale)*[cos(theta*D2R) -sin(theta*D2R);
                          sin(theta*D2R)  cos(theta*D2R)];
H12(1:2,3) = -[tu; tv];
           
%MATLAB's tform structure assumes a post-multiply
%homography so use transpose of H12
tform = maketform('affine',H12');

if show_figs >= 1
    figure(11);
    %warp the input image I2 using the
    %determined transform.
    %note that MATLAB's imtransform function
    %doesn't not place the image J2 in mosaic
    %space using the translation offsets
    %(tu,tv).  this has to be done manually.
    %    J2rs = imtransform(I2,tform,'bicubic');
    J2rs = imrotate(I2,-theta,'bilinear','crop');
    J2rs = imresize(J2rs,1/scale,'bilinear');
    imagesc(J2rs); colormap gray; axis on; grid; truesize;
    title('Rotated and Scaled Input Image');
end

if show_figs >= 1
    figure(12);
    %place the rotated and scaled image in
    %the control image's coordinate frame
    [Jy Jx] = size(J2rs);
    if tv < 0
        yi = 1-tv;
        yf = min(rowdim,Jy-tv);
        vi = 1;
        vf = min(rowdim+tv,Jy);
    else
        yi = 1;
        yf = min(rowdim,Jy-tv);
        vi = tv+1;
        vf = min(Jy,rowdim+tv);
    end
    
    if tu < 0
        xi = 1-tu;
        xf = min(coldim,Jx-tu);
        ui = 1;
        uf = min(coldim+tu,Jx);
    else
        xi = 1;
        xf = min(coldim,Jx-tu);
        ui = tu+1;
        uf = min(Jx,coldim+tu);
    end
    
    %windows so it will match frame of control image
    J2 = zeros(rowdim,coldim);
    J2(yi:yf,xi:xf) = J2rs(vi:vf,ui:uf);
    imagesc(J2); colormap gray; axis on; grid; truesize;
    title('Registered Input Image');
end


%==========================================
% ASSIGN OUTPUT ARGUMENTS
%==========================================
if NARGOUT > 0
    if NARGOUT >= 3
        varargout{1} = scale;
        varargout{2} = theta;
        varargout{3} = [tu tv];
    end
    if NARGOUT >= 4
        varargout{4} = J2;
    end
end