function lut = lplut(f1dim,f2dim,wdim,rdim,tdim,varargin)
% CREATES Lookup table
% defines LUT between log-polar and cartesian coordinates
% used to map magnitude of FT in cartesian to log-polar

% History:
% DATE      WHO     COMMENTS
%---------  -----   --------------------------------
%04/24/2002 RME     Modified Oscar's original p5c.m script
%                   into a function that maps
%                   a freqency annulus to log-polar rather
%                   than a general rectangular section of FT.
%                   Also rewrote FOR-LOOP as an outter product
%                   of two vectors improving algorithm speed
%                   by an order of magnitude.
%                   Also changed 
%05/28/2002 OP      includes fd1, fd2 in mapstruct, 
%                   only saves mapstruct
%04/21/2002 OP      stretches lcmap into w1,w2 vectors for faster
%                   assignment


%=====================================================
%DEFINE CONCENTRIC ANNULUS OF FREQUENCY SPECTRUM
%TO TRANSFER INTO LOG-POLAR COORDINATES.
%THE HIGHPASS EMPHASIS FILTER APPLIED IN ROTSCALE
%DEFINES THE RADIUS OF THE BANDPASS FREQUENCY ANNULUS.
%=====================================================
%wdim must be <= min(f1dim/2,f2dim/2);
%where f1dim, f2dim are the number of
%samples in vertical and horizontal axes
%of the fourier transform, repectively.
if wdim > f1dim/2
    msg = sprintf('wdim = %g > f1dim/2 = %g, setting wdim = %g', ...
                  wdim,f1dim/2,f1dim/2);
    disp(msg);
    wdim = f1dim/2;
elseif wdim > f2dim/2
    msg = sprintf('wdim = %g > f2dim/2 = %g, setting wdim = %g', ...
                   wdim,f2dim/2,f2dim/2);
    disp(msg);
    wdim = f2dim/2;
end

%============================================
%DEFINE DIMENSIONS OF THE LOG-POLOAR
%MAGNITUDE SPECTRUM REPRESENTATION
%============================================
%set minimum values
% if rdim < 512
%     rdim = 512; %rho (radius samples)
% end
% if tdim < 512
%     tdim = 512; %theta (angular samples)
% end

%============================================
%DEFINE SOME CONSTANTS
%============================================
%base used to calculate log of radius
%example:
%
%  base^128 = 256
%
%maps 256 rows in cartesian spectrum to
%128 rows in polar plane
base = exp(log(f2dim)/tdim); %maps f2dim rows into tdim rows

%degrees to radians
D2R = pi/180;

%============================================
%DEFINE SOME PARAMETERS CONTROLING
%LOG-POLAR CONVERSION
%============================================
%thresh together with hscale controls 
%minimum radius to be mapped avoiding 'blown up'
%pixels close to origin of frequency axis.
if length(varargin) > 0
    thresh = varargin{1};
else
    %set default value of threshold
    thresh = 600;
end
hscale = (rdim+thresh)/(log2(wdim-1)/log2(base));

%min radius mapped into log-polar coordinates
rmin = base^((thresh+1)/hscale);

%scaling to map 180 degrees in tdim samples
vscale = tdim/180;

%===============================================
%CREATE LOOK-UP-TABLE
%the original block of code was written
%as nested FOR LOOPS.
%it has been rewritten more efficienty
%using vector algebra.
%===============================================
% ORIGINAL NESTED FOR-LOOPS
% for i = 1:tdim
%     theta = (i-1)/vscale; %angle
%     for j = 1:rdim
%         rho = base^((j+thresh)/hscale); %radius
%         %cartesian coords
%         w1 = round(rho*cos(theta*D2R));
%         w2 = round(rho*sin(theta*D2R));
%         %negative and positive w1, positive w2 only
%         %i.e. upper half of spectra only
%         if abs(w1)<=wdim & w2<=wdim & w2>=0
%             lcmap.j(i,j) = w1; %relative to center of image
%             lcmap.i(i,j) = w2; %relative to center of image
%         end
%     end
% end

ii = 1:tdim;
jj = 1:rdim;
theta = (ii-1)/vscale; %vector of sampled angles
rho = base.^((jj+thresh)/hscale); %vector of sampled radii

%(w1,w2) correspond to the cartesian coordinates
%in the freq plane
w1 = cos(theta*D2R)'*rho;
w2 = sin(theta*D2R)'*rho;

%find nearest sample
lcmap.j = round(w1); %relative to center of image
lcmap.i = round(w2); %relative to center of image

%map image center relative indexing
%to standard matlab array indexing
w2 = f2dim/2+1-lcmap.i(:);
w1 = f1dim/2+1+lcmap.j(:);

%vector of indexes to map cartesian to log-polar
lut.indvec = w2+(w1-1)*f2dim;

[w2lcmap,w1lcmap] = size(lcmap.i);
lut.base = base;
lut.hscale = hscale;
lut.vscale = vscale;
lut.w1lcmap = w1lcmap;
lut.w2lcmap = w2lcmap;
lut.f1dim = f1dim;
lut.f2dim = f2dim;
lut.tdim  = tdim;
lut.rdim  = rdim;
lut.thresh = thresh;