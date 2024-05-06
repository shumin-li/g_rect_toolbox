if 1 %S
  I1 = imread('./images/fourier_control.tif');
  I2 = imread('./images/fourier_input.tif');
  [scale,theta,t] = fftreg(I1,I2);
  
  tform = tform_from_similarity(scale,theta,t,(size(I1)-1)./2);
  Imos = Merge_pair(I1,I2,tform);
end
