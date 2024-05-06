function errGeoFit = g_error_geofit(cv,imgWidth,imgHeight,xp,yp,ic,jc,...
                                   hfov,lambda,phi,H,theta,...
                                   hfov0,lambda0,phi0,H0,theta0,...
                                   hfovGuess,lambdaGuess,phiGuess,HGuess,thetaGuess,...
                                   dhfov,dlambda,dphi,dH,dtheta,...
                                   LON0,LAT0,...
                                   i_gcp,j_gcp,lon_gcp0,lat_gcp0,h_gcp,...
                                   theOrder,frameRef);

                               
for i = 1:length(theOrder)
  if theOrder(i) == 1; hfov   = cv(i); end
  if theOrder(i) == 2; lambda = cv(i); end
  if theOrder(i) == 3; phi    = cv(i); end
  if theOrder(i) == 4; H      = cv(i); end
  if theOrder(i) == 5; theta  = cv(i); end
end

% Perform the geometrical transformation
[LON LAT] = g_pix2ll(xp,yp,imgWidth,imgHeight,ic,jc,...
                     hfov,lambda,phi,theta,H,LON0,LAT0,frameRef);

% Calculate the error between ground control points (GCPs) 
% and image control points once georectified. 
%
% This error (errGeoFit) is the error associated with the geometrical fit,
% as opposed to the error associated with a polynomial fit that can be 
% calculated if requested by the user. 
%

% Determine the number of CGP
ngcp = length(i_gcp);

ngcpFinite = 0;
errGeoFit  = 0.0;

% Project the GCPs onto the water surface given their elevation
[lon_gcp,lat_gcp] = g_proj_GCP(LON0,LAT0,H,lon_gcp0,lat_gcp0,h_gcp,frameRef);

for k = 1:ngcp
    
  % Calculate the distance (i.e. error) between GCP and rectificed ICPs.
  distance = g_dist(lon_gcp(k),lat_gcp(k),LON(k),LAT(k),frameRef);
  
  % Check if the distance is finite. The distance may be NaN for some
  % GCPs that may temporarily be above the horizon. Those points are 
  % blanked out in the function g_pix2ll.
  if isfinite(distance) == 1 
    errGeoFit = errGeoFit + distance^2;
    ngcpFinite = ngcpFinite + 1;
  else
    errGeoFit = Inf;
  end
  
end

% rms distance
errGeoFit = sqrt(errGeoFit/ngcpFinite);

% Check if the parameters are within the specified uncertainties.
% If not set the error to infinity.
if abs(hfov - hfovGuess)     > dhfov;   errGeoFit = inf; end
if abs(lambda - lambdaGuess) > dlambda; errGeoFit = inf; end
if abs(phi - phiGuess)       > dphi;    errGeoFit = inf; end
if abs(H - HGuess)           > dH;      errGeoFit = inf; end
if abs(theta - thetaGuess)   > dtheta;  errGeoFit = inf; end
