function [tu,tv,peakcorr] = find_xlate2(I1,I2);
%FIND_XLATE2 finds relative image translation
%   Uses Fourier methods to determine phase shift and thus
%   image translation.

% History:
% DATE      WHO     COMMENTS
%---------  -----   --------------------------------
%12/2002    Ali     Added smoothing to phase correlation matrix.
%10/2002    RME     Fixed bug, function now properly returns 
%                   translation vector in I1's coordinate frame
%05/2002    RME     Minor modifications, returns shift
%                   as measured in I1's coordinate frame
%05/2000    OP      Created and implemented
%Hanu's original
%OP presentation modifications 18-APR-2000
%change in size of transform to insure linear convolution

[I1_h,I1_w]=size(I1);
[I2_h,I2_w]=size(I2);

%find the default h,w for the inputs
def_w = 2*round(max(I1_w,I2_w)/2);
def_h = 2*round(max(I1_h,I2_h)/2);

I1_fft = fft2(I1,def_h,def_w);
I2_fft = fft2(I2,def_h,def_w);


%phase correlation technique
%better results than pure correlation
CPS = (I1_fft.*conj(I2_fft));
CPS = CPS./abs(CPS);
im_xlate = real(fftshift(ifft2(CPS)));

%peakcorr = max(im_xlate(:));
%[ii jj] = find(im_xlate == peakcorr);

% Added by Ali Can. Dec.5.2002.
% Phase correlation matrix is smoothed before searching the maximum
% this is essential for 
% 1. tolerating minor image-to-image transformation modelling errors
% 2. to reduce the effect of bias towards no translation

hf = ones(3,3);
hf = hf ./ sum(hf(:));
im_xlate_s = imfilter(im_xlate,hf,'same','circular');
peakcorr = max(im_xlate_s(:));
[ii jj] = find(im_xlate_s == peakcorr);
%figure, plot(max(im_xlate));
%figure, plot(max(im_xlate_s));
%figure, my_imshow(im_xlate);
%figure, my_imshow(im_xlate_s);

%%%%%% End of Ali's addition Dec.5.2002

tv = ii - def_h/2 - 1; 
tu = jj - def_w/2 - 1; 