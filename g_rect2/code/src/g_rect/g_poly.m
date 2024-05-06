function [LONpc, LATpc, err_polyfit] = g_poly(LON,LAT,LON0,LAT0,i_gcp,j_gcp,lon_gcp,lat_gcp,p_order,frameRef);

ngcp=length(i_gcp);

% LON0 and LAT0 are removed to facilitate the fiminsearch algorithm
for k = 1:ngcp

    lonlon(k) =  LON(i_gcp(k),j_gcp(k))-LON0;
    latlat(k) =  LAT(i_gcp(k),j_gcp(k))-LAT0;
    err_lon(k) = lonlon(k)-(lon_gcp(k)-LON0);
    err_lat(k) = latlat(k)-(lat_gcp(k)-LAT0);  
  
    Delta_lon = LON(i_gcp(k)+1,j_gcp(k)) - LON(i_gcp(k),j_gcp(k));
    Delta_lat = LAT(i_gcp(k)+1,j_gcp(k)) - LAT(i_gcp(k),j_gcp(k));
  
    if (abs(err_lon) - Delta_lon) < 0
      err_lon(k) = 0.0;
    end
    if (abs(err_lat) - Delta_lat) < 0
      err_lat(k) = 0.0;
    end

end
LON = LON - LON0; 
LAT = LAT - LAT0;

options = optimset('MaxFunEvals',1000000,'MaxIter',1000000,'TolFun',1.d-12,'TolX',1.d-12);

% The fminsearch is done twice for more accuracy. Otherwise, sometime it is 
% not the true minimum that is found in the first pass.

if p_order == 1
  
  a(1:3) = 0.0;
  b(1:3) = 0.0;
  a = fminsearch('g_error_polyfit',a,options,lonlon,latlat,err_lon,p_order);
  a = fminsearch('g_error_polyfit',a,options,lonlon,latlat,err_lon,p_order);
  b = fminsearch('g_error_polyfit',b,options,lonlon,latlat,err_lat,p_order);
  b = fminsearch('g_error_polyfit',b,options,lonlon,latlat,err_lat,p_order);
    
  LONpc = LON-(a(1)*LON+a(2)*LAT+a(3));
  LATpc = LAT-(b(1)*LON+b(2)*LAT+b(3));
  
elseif p_order == 2
  
  % First pass - 1st order
  a(1:3) = 0.0;
  b(1:3) = 0.0;
  a = fminsearch('g_error_polyfit',a,options,lonlon,latlat,err_lon,1);
  a = fminsearch('g_error_polyfit',a,options,lonlon,latlat,err_lon,1);
  b = fminsearch('g_error_polyfit',b,options,lonlon,latlat,err_lat,1);
  b = fminsearch('g_error_polyfit',b,options,lonlon,latlat,err_lat,1);
    
  LONpc = LON-(a(1)*LON+a(2)*LAT+a(3));
  LATpc = LAT-(b(1)*LON+b(2)*LAT+b(3));

  LON = LONpc + LON0;
  LAT = LATpc + LAT0;

  % Second pass - 2nd order
  for k = 1:ngcp
    lonlon(k) =  LON(i_gcp(k),j_gcp(k))-LON0;
    latlat(k) =  LAT(i_gcp(k),j_gcp(k))-LAT0;
    err_lon(k) = lonlon(k)-(lon_gcp(k)-LON0);
    err_lat(k) = latlat(k)-(lat_gcp(k)-LAT0);  
  end
  LON = LON - LON0; 
  LAT = LAT - LAT0;

  a(1:6) = 0.0;
  b(1:6) = 0.0;
  a = fminsearch('g_error_polyfit',a,options,lonlon,latlat,err_lon,2);
  a = fminsearch('g_error_polyfit',a,options,lonlon,latlat,err_lon,2);
  b = fminsearch('g_error_polyfit',b,options,lonlon,latlat,err_lat,2);
  b = fminsearch('g_error_polyfit',b,options,lonlon,latlat,err_lat,2);
  LONpc = LON-(a(1)*LON.^2+a(2)*LAT.^2+a(3)*LON.*LAT+a(4)*LON+a(5)*LAT+a(6));
  LATpc = LAT-(b(1)*LON.^2+b(2)*LAT.^2+b(3)*LON.*LAT+b(4)*LON+b(5)*LAT+b(6));
  
end

% Add the LON0 and LAT0
LONpc = LONpc + LON0;
LATpc = LATpc + LAT0;

% Recalculate the error after correction.
err_polyfit=0;
for k = 1:ngcp
    
  DX = g_dist(LONpc(i_gcp(k),j_gcp(k)),LATpc(i_gcp(k),j_gcp(k)),lon_gcp(k),lat_gcp(k),frameRef);
  err_polyfit = err_polyfit + DX^2;

end
err_polyfit = sqrt(err_polyfit/ngcp);