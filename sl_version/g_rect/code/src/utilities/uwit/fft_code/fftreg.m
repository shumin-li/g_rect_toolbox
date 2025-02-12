function [varargout] = fftreg(I1,I2,varargin)
%FFTREG Registers an image pair for rotation, scale, and
%       and tranlation using Fourier transform properties.
%
%   [SCALE,THETA,TRAN] = FFTREG(I1,I2) registers a pair of images
%   I1,I2 using Fourier based methods which can account for images
%   which are related through a scaling, rotation, and translation.
%   The parameters SCALE,THETA, and TRAN are all measured relative
%   to I1's coordinate frame.  TRAN is a 2x1 vector of translations
%   [tu tv]'.
%
%   [SCALE,THETA,TRAN,J] = FFTREG(I1,I2) and
%   [J] = FFTREG(I1,I2) optionally returns the registered
%   output image I2 in I1's coordinate frame.
%
%   FFTREG(I1,I2) without any output argument assignments generates
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
%   I1 = rgb2gray(imread('westconcordaerial.png'));
%   [rdim,cdim] = size(I1);
%   scale = 1.2;
%   theta = 25*pi/180;
%   t = [-15 -15];
%   H12 = eye(3);
%   R12 = [cos(theta) -sin(theta); sin(theta)  cos(theta)];
%   H12(1:2,1:2) = (1/scale)*R12;
%   H12(1:2,3) = t';
%   H21 = H12^-1;
%   cntr = (size(I1)-1)./2;
%   xo = cntr(2); yo = cntr(1);
%   Htl = [1  0  xo; 0  1  yo; 0  0   1];
%   tform = maketform('affine',(Htl*H21*Htl^-1)');
%   xdata = [1 size(I1,2)];
%   ydata = [1 size(I1,1)];
%   I2 = imtransform(I1,tform,'bicubic','xdata',xdata,'ydata',ydata);
%   fftreg(I1,I2);
%
%EXAMPLE2
%
%   I1 = imread('images/ESC.0565.tif');
%   I2 = imread('images/ESC.0564.tif');
%   fftreg(I1,I2);

%HISTORY
%DATE       WHO             COMMENT
%--------   -------------   -----------------------------
%10/2002    Ryan Eustice    Changed to use imtransform during
%                           calculation of translation instead
%                           of imrotate & imresize.
%10/2002    Ryan Eustice    Changed to use Matlab's imtransform
%                           function to apply the homography which 
%                           registers the image pair.
%10/2002    Ryan Eustice    Changed function name from rstreg to fftreg
%05/2002    Ryan Eustice    Streamlined and speed up original code.
%05/2000    Oscar Pizarro   Originally created and implemented
%                           all functionality of algorithm.


show_figs = 0;
Imaskflag = 0;
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
        case 'mask';      Imask = varargin{ii+1}; ii=ii+2; Imaskflag = 1;           
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
    cos_support = round(0.1*min(rowdim,coldim));
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
hI1 = (real(ifft2(hF1)));
hI1 = hI1(1:rowdim,1:coldim);
hI2 = (real(ifft2(hF2)));
hI2 = hI2(1:rowdim,1:coldim);

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

%maxval  = max(peakM(:));
%[iind,jind] = find(peakM == maxval);

% Added by Ali Can. Dec.5.2002.
% Correlation matrix is smoothed before searching the maximum
% this is essential for 
% 1. tolerating minor image-to-image transformation modelling errors
% 2. to reduce the effect of bias towards no translation

hf = ones(3,3);
hf = hf ./ sum(hf(:));
peakM_s = imfilter(peakM,hf,'same','circular');
maxval  = max(peakM_s(:));
[iind,jind] = find(peakM_s == maxval);
%figure, plot(max(peakM));
%figure, plot(max(peakM_s));
%figure, my_imshow(peakM);
%figure, my_imshow(peakM_s);

%%%%%% End of Ali's addition Dec.5.2002


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
%using MATLAB's tform structure and imtransform

tform = tform_from_similarity(scale,theta,[0, 0],(size(I1)-1)./2);

%warp the input image I2 using the
%determined transform.
hJ2 = imtransform(hI2,tform,'bicubic', ...
		 'udata',[1 size(I2,2)],'vdata',[1 size(I2,1)], ...       
		 'xdata',[1 size(I1,2)],'ydata',[1 size(I1,1)]);
%rotate by 180 degrees
hJ2_180 = flipud(fliplr(hJ2));

% find translation using phase correlation technique
[tu1,tv1,peakcorr1] = find_xlate2(hI1,hJ2);
[tu2,tv2,peakcorr2] = find_xlate2(hI1,hJ2_180);

% If a mask is provided, ignore 180 degree ambiguity
if  Imaskflag == 1
    tu = tu1;
    tv = tv1;
    peakcorr = peakcorr1;
else
    if peakcorr1 > peakcorr2
        tu = tu1;
        tv = tv1;
        peakcorr = peakcorr1;
    else
        tu = tu2;
        tv = tv2;
        peakcorr = peakcorr2;
        %theta = theta+180;
    end
end;
    
%conserve memory and clear intermediate variables
clear tu1 tv1 peakcorr1 tu2 tv2 peakcorr2 hI2 hJ2_180;


%Resolve the periodicity of translation by a hypoyhesize-test scheme
if  Imaskflag == 1
    [tu, tv] = resolve_xlate2(I1, I2, scale,theta,[tu, tv],(size(I1)-1)./2,'mask',Imask);
else
    [tu, tv] = resolve_xlate2(I1, I2, scale,theta,[tu, tv],(size(I1)-1)./2);
end;
    
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

tform = tform_from_similarity(scale,theta,[tu, tv],(size(I1)-1)./2);

%register the input image I2 using the
%determined transform into I1's coordinate frame
J2 = imtransform(I2,tform,'bicubic', ...
		 'udata',[1 size(I2,2)],'vdata',[1 size(I2,1)], ...       
		 'xdata',[1 size(I1,2)],'ydata',[1 size(I1,1)]);

if show_figs >= 1
  figure(12);
  imagesc(J2); colormap gray; axis on; grid; truesize;
  title('Registered Input Image');
end

%==========================================
% ASSIGN OUTPUT ARGUMENTS
%==========================================
if NARGOUT > 0
    if NARGOUT == 1
        varargout{1} = J2;
    end
    if NARGOUT >= 3
        varargout{1} = scale;
        varargout{2} = theta;
        varargout{3} = [tu tv];
    end
    if NARGOUT >= 4
        varargout{4} = J2;
    end
end