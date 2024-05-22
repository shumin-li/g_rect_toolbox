

%Resolve the periodicity of translation by a hypoyhesize-test scheme
%Dec.08.2002 Ali Can

function [tu, tv] = resolve_xlate2(I1, I2, scale, theta, t, cntr, varargin)


%===============================================
% CHECK FOR OPTIONAL ARGUMENTS for the mask
%===============================================
NARGIN = nargin;
Imaskflag = 0;
if NARGIN < 6
    error('Invalid number of arguments');
elseif NARGIN > 6
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
    thresh = 0.1 * sum(Imask(:));
else
    thresh = 0.1 * size(I1,1) *size(I1,2);
end;

Cx(1) = t(1);
Cy(1) = t(2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Minimum overlap is assumed to be 10 percent
if t(1) < -0.1 * size(I1,2)
    Cx(2) = t(1) + size(I1,2);
elseif t(1) > 0.1 * size(I1,2)
    Cx(2) = t(1) - size(I1,2);
end;
if t(2) < -0.1 * size(I1,1)
    Cy(2) = t(2) + size(I1,1);
elseif t(2) > 0.1 * size(I1,1)
    Cy(2) = t(2) - size(I1,1);
end;
Cxx = Cx
Cyy = Cy

min_sum = 255;
tu = Cx(1);
tv = Cy(1);
%test the translation hypothesis
for ii=1:length(Cx)
    for jj=1:length(Cy)
        tform = tform_from_similarity(scale,theta,[Cx(ii), Cy(jj)],cntr);

            
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

        %find the pixels in the overlapping area
        ind = find((J1~=0) & (J2~=0));
        JT = double(J1(ind));
        JN1 = (JT - mean(JT)) / (std(JT)+0.000001);
        JT = double(J2(ind));
        JN2 = (JT - mean(JT)) / (std(JT)+0.000001);
        Mdiff = sum(abs(JN1 - JN2));
        Mdiff = Mdiff / (length(ind)+1)
        
        LL = length(ind)
        %impose at least 10 percent overlap
        if ((length(ind) > thresh) & (Mdiff < min_sum))
            min_sum = Mdiff;
            tu = Cx(ii);
            tv = Cy(jj);
        end;
        clear ind;
    end;
end;

