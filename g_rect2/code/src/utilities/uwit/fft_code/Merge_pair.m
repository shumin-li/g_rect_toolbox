function [I_mos] =  Merge_pair(I1, I2, tform, varargin)

%===============================================
% CHECK FOR OPTIONAL ARGUMENTS for the mask
%===============================================
NARGIN = nargin;
Imaskflag = 0;
if NARGIN < 3
    error('Invalid number of arguments');
elseif NARGIN > 3
    done = 0;
    ii = 1;
    while ~done
        switch lower(varargin{ii})
        case 'mask';      Imask = varargin{ii+1}; ii=ii+2; Imaskflag = 1; 
        otherwise
            msg = sprintf('Unknown argument given');
            error(msg);
        end
        if ii >= length(varargin); done = 1; end
    end
end

if Imaskflag == 1
    I1 = immultiply(imadd(I1,1),uint8(Imask));
    I2 = immultiply(imadd(I2,1),uint8(Imask));
end;
    
%warp the input image I2 into I1's frame using
%the determined transform.  calculate the warped
%image bounds so that both images are completly
%contained
inbounds = [1 1; size(I1,2) size(I1,1)];
outbounds = findbounds(tform,inbounds);
mosaicbounds(1,:) = min(inbounds(1,:),outbounds(1,:));
mosaicbounds(2,:) = max(inbounds(2,:),outbounds(2,:));
xdata = mosaicbounds(:,1)';
ydata = mosaicbounds(:,2)';
J2 = imtransform(I2,tform,'bicubic','xdata',xdata,'ydata',ydata);

%place the original I1 image into the mosaic canvas
J1 = imtransform(I1,maketform('affine',eye(3)),'bicubic', ...
		 'xdata',xdata,'ydata',ydata);

%generate a mosaic by creating an average of the two
ind = find((J1~=0) & (J2~=0));
Mavg = double(J1)+double(J2);
Mavg(ind) = Mavg(ind)/2;
Mavg = uint8(Mavg);

figure(1); clf;
imagesc(I1); axis on; colormap gray;
title('Control Image');

figure(2); clf;
imagesc(I2); axis on; colormap gray;
title('Input Image');

figure(3); clf;
imshow(xdata,ydata,Mavg); axis on;
title('Registered Input Image (Average Intensity)');

%Return the mosaic as an output.
I_mos = Mavg; 
