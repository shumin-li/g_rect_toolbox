%BLEND_DEMO script

load blend_demo
BASE = double(BASE);
INPUT = double(INPUT);

path(path,'../blending');

[i j] = find(BASE>-inf);

image_pair = [input_points base_points];
im_xy = image_pair(:,1:2);
im_xy(:,3) = 1;
im_uv = image_pair(:,3:4);
im_uv(:,3) = 1;
xmatrix = im_xy \ im_uv;


JI = [j i ones(length(i),1)];
VU = JI*xmatrix;
v = VU(:,1);
u = VU(:,2);

tform = cp2tform(input_points,base_points,'affine');

[WARP X Y] = imtransform(INPUT,tform);
[rowB colB] = size(BASE);
[rowW colW] = size(WARP);
MOSAIC = zeros(rowB+127,colB+25);
MOSAIC(126:126+rowW-1,1:colW) = WARP;
MOSAIC(1:rowB,26:end) = BASE;
figure(1);
imagesc(MOSAIC);colormap gray;grid on;truesize;
title('MOSAIC UNBLENDED');

TOP = zeros(rowB+127,colB+25);
BOTTOM = TOP;
MASK = TOP;
MASK(150:end,1:570) = 1;
TOP(1:rowB,26:end) = BASE;
BOTTOM(126:126+rowW-1,1:colW) = WARP;

MOSAIC_BLENDED = blend(BOTTOM,TOP,MASK);
figure(2);
imagesc(MOSAIC_BLENDED);colormap gray;grid on;truesize;
title('MOSAIC BLENDED');