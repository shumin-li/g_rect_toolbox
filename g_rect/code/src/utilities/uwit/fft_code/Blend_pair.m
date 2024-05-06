
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

R = (zeros(size(J1)));
%generate a mosaic by creating an average of the two
[ii,jj] = find((J2~=0));
iimin = min(ii);
jjmin = min(jj);
ind_t = find(ii > iimin+12 & jj > jjmin+12);
ii = ii(ind_t); jj = jj(ind_t);
ind = sub2ind(size(J1),ii,jj);
%R(ind) = 1;
%imshow(uint8(255*R));
%Return the mosaic as an output.

R(300:end,:) = 1;
keyboard
I_mos = blend(J2,J1,R); 