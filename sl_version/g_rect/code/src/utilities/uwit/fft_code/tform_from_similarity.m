function tform = tform_from_similarity(scale,theta,t,cntr)

%=============================================
% CREATE A MATLAB TFORM STRUCTURE WHICH
% CAN BE USED BY IMTRANSFORM TO WARP
% THE INPUT IMAGE
%=============================================
%calculate a pre-multiply homography H12 which
%rotates and scales I2 towards I1
D2R = pi/180;
H12 = eye(3);
R12 = [cos(theta*D2R) -sin(theta*D2R);
       sin(theta*D2R)  cos(theta*D2R)];
H12(1:2,1:2) = (1/scale)*R12;
H12(1:2,3) = t';


%create a homography to map a coordinate system
%located at the center of the image, to one which
%is located at the top left corner
xo = cntr(2); yo = cntr(1);
Htl = [1  0  xo;
       0  1  yo;
       0  0   1];
           
%MATLAB's tform structure assumes a post-multiply
%homography so use transpose of H12
tform = maketform('affine',(Htl*H12*Htl^-1)');