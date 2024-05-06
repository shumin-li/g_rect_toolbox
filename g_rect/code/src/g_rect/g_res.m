function res = g_res_field(LON, LAT, frameRef)
% g_res_field - Function calculating the loss of resolution with de distance
% from the camera
%
% Inputs:
% 
%    LON      : Longitude or x-positon matrix obtained from g_rect
%    LAT      : Latitude or y-position matrix obtained from g_rect
%    frameRef : 'Geodetic' of 'Cartesian'.
%
% Outputs:
%    
%    res : The field of resolution which is degrading with distance from
%    the camera
% 
% Authors: 
%     Daniel Bourgault
%     Institut des sciences de la mer de Rimouski
%     email: daniel_bourgault@uqar.ca 
%     February 2013
%
%    Elie Dumas-Lefebvre
%    Institut des Science de la Mer de Rimouski
%    Note: Matricial formulation of the calculation for a faster execution
%    email: elie.dumas-lefebvre@uqar.ca
%    March 2019
%

% LAT and LON difference in the x-axis
dLATi = diff(LAT, 1, 2);
dLONi = diff(LON, 1, 2);

% LAT and LON difference in the y-axis
dLATj = diff(LAT, 1, 1);
dLONj = diff(LON, 1, 1);

% Mean LAT in both x and y axis
LAT_meani = 0.5*(LAT(:, 2:end) + LAT(:, 1:end-1));
LAT_meanj = 0.5*(LAT(2:end, :) + LAT(1:end-1, :));

% Add a point at boundaries such that the resolution matrix 
% has the same size of the LAT LON matrices 
dLATi(:,end+1)     = dLATi(:,end);
dLONi(:,end+1)     = dLONi(:,end);
dLATj(end+1,:)     = dLATj(end,:);
dLONj(end+1,:)     = dLONj(end,:);
LAT_meani(:,end+1) = LAT_meani(:,end);
LAT_meanj(end+1,:) = LAT_meani(end,:);

% Conversion from degree to meters
meterPerDegLat  = 1852*60.0;
meterPerDegLoni = meterPerDegLat.*cosd(LAT_meani);
meterPerDegLonj = meterPerDegLat.*cosd(LAT_meanj);


if strcmp(frameRef,'Geodetic') == true
    
    % Conversion from degrees to meters
    dxi = dLONi.*meterPerDegLoni;
    dxj = dLONj.*meterPerDegLonj;
    dyi = dLATi.*meterPerDegLat;
    dyj = dLATj.*meterPerDegLat;
    
elseif strcmp(frameRef,'Cartesian') == true

    % Lab case. Data are already in meters. No conversion required.    
    dxi = dLONi;
    dxj = dLONj;
    dyi = dLATi;
    dyj = dLATj;
    
end

% Distances in x and y axis
deltai = sqrt(dxi.^2 + dyi.^2);
deltaj = sqrt(dxj.^2 + dyj.^2);

% field of resolution
res = sqrt(deltai.^2 + deltaj.^2);