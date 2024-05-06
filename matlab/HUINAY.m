% Rectification stuff
%
%  Note - infinfo doesn't get ALL metadata from the tiffs. Need
% to download and install 'exiftool' (exiftool.org)
% Then run exiftool (google it for source):
%
%        exiftool -r -n -all -csv *.JPG > metadata.csv
%       
%   -n for no formatting, all tags starting with Gimbal or GPS, or
%   containing Altitude:
%        exiftool -csv -r -n -DateTimeOriginal -FOV "-Gimbal*" -"*Altitude*" "-GPS*"  *.JPG   > metadata2.csv

addpath(genpath('/ocean/rich/home/Chile/photo/g_rect/code/src'));
rmpath /Users/rich/home/Chile/photo/capsule-6352444/code/src/utilities/m_map

%%
C=load('../../matlab/Patcoast');

plot(C.ncst(:,1),C.ncst(:,2))

I1=imfinfo('../orig/IMG_2362.JPG')

hFOV=2*atand(35/(2*4.5));  % 4.5mm focal length
hFOV=2*atand(35/(2*25));  % Specs say 25 is minimum 4.5mm focal length

I2=imfinfo('../drone_SL/DJI_0251.JPG')

%%
addpath /ocean/rich/home/metro/drifters/matlab/zoharby-plot_google_map-f73f0ce

%%
g_viz_geodetic( {'../proc/DJI_0261_grect.mat','../proc/DJI_0265_grect.mat','../proc/DJI_0245_grect.mat',...
                '../proc/DJI_0259_grect.mat'},'axislimits',...
                [-72-28.5/60 -72-24.8/60 -42-23.45/60 -42-21.55/60]);
            
% print -dpng -r300 Huinay_Front

            
 %           {'../drone_SL/DJI_0259.mat','../drone_SL/DJI_0261.mat',...
 %               '../drone_SL/DJI_0245.mat'},...
%%


 %% Example with drifters (add drifers code below)
 
 figure(2);set(gcf,'color','w');
 AxisLimits=[-72-25.35/60 -72-25.23/60 -42-22.95/60 -42-22.81/60];
 g_viz_geodetic('../proc/DJI_0171_grect.mat','axislimits',AxisLimits,...
      'showtime',1);

mtime= datenum(2023,01,6,16,4,5);

%% Second drifters example

 figure(2);set(gcf,'color','w');
 AxisLimits=[-72-25.40/60 -72-25.25/60 -42-22.90/60 -42-22.76/60];
 g_viz_geodetic('../proc/DJI_0041_grect.mat','axislimits',AxisLimits,...
      'showtime',1);

mtime= datenum(2023,01,6,15,49,30);

%%
load data_drifters

for k=1:length(tracks)
    if tracks(k).mission_start< mtime & tracks(k).mission_end> mtime
        lg=interp1(tracks(k).time,tracks(k).lon,mtime);
        lt=interp1(tracks(k).time,tracks(k).lat,mtime);
        
        m_line(tracks(k).lon,tracks(k).lat,'marker','o','color','b');
        m_line(lg,lt,'marker','o','linewi',2,'color','r');
        m_text(lg,lt,[' ' tracks(k).id]);
    end
end

% print -dpng -r300 Boatwithdrifters
% print -dpng -r300 Boatwithdrifters2

%%
 

g_viz_geodetic( {'../proc/DJI_0333_grect.mat','../proc/DJI_0340_grect.mat',...
                 '../proc/DJI_0335_grect.mat','../proc/DJI_0334_grect.mat'},...
    'axislimits',[-72-26.0/60 -72-24.7/60 -42-22.9/60 -42-22.2/60],'raw',false);

% print -dpng -r300 Huinay_Delta


%%

clf;
imagesc(peaks);
hold on;
image([30 60],[20 30],5,'alphadata',.5);

%%
g_viz_geodetic( {'../proc/DJI_0309_grect.mat'},'raw',false);

%%
g_viz_geodetic( {'../proc/DJI_20210905_140558_grect.mat'},'raw',true,...
    'axislimits',[-68-30.8/60 -68-30/60 48+35.2/60 48+35.7/60],'showtime',1);

mtime=datenum(2021,9,5,14,05,58);

%%
load /ocean/rich/home/TREX21/matlab/SaucierGPS
ii=gpsFJS(2).mtime>mtime-10/1440 & gpsFJS(2).mtime<mtime+10/1440;


line(gpsFJS(2).lon(ii),gpsFJS(2).lat(ii),'marker','.','linewi',2,'linest','--');
xfjs=interp1(gpsFJS(2).mtime(ii),gpsFJS(2).lon(ii),mtime);
yfjs=interp1(gpsFJS(2).mtime(ii),gpsFJS(2).lat(ii),mtime);
line(xfjs,yfjs,'marker','o','color','r','linewi',2);

%%
load /ocean/rich/home/TREX21/matlab/Coriolis_GPS_fixed
ii=gpsC.mtime>mtime-10/1440 & gpsC.mtime<mtime+10/1440;


line(gpsC.lon(ii),gpsC.lat(ii),'marker','.','linewi',2,'linest','--','color','c');
xfjs=interp1(gpsC.mtime(ii),gpsC.lon(ii),mtime);
yfjs=interp1(gpsC.mtime(ii),gpsC.lat(ii),mtime);
line(xfjs,yfjs,'marker','o','color','r','linewi',2);



%% From Station lookout tower

g_rect('g_rect_paramsi1.dat',6);

%%
g_viz_geodetic( {'../proc/IMG_2406_grect.mat','../proc/IMG_2404_grect.mat'},...
    'axislimits',[-72-26.0/60 -72-24.7/60 -42-23.2/60 -42-22.3/60],'raw',true);

addpath /ocean/rich/home/metro/drifters/matlab/zoharby-plot_google_map-f73f0ce/
plot_google_map('maptype','satellite');

% print -dpng -r300 Huinay_Delta

axdeg('x');axdeg('y');
set(gca,'linewi',2);
title('Weird front downstream of fish farm');

% print -dpng FishFarmPlume

%%

clf;
load /ocean/rich/home/Chile/matlab/Patcoast
plot(ncst(:,1),ncst(:,2),'color','r');
axis([-72-26.0/60 -72-24.7/60 -42-23.2/60 -42-22.3/60]);
axis([-72.7 -72.3 -42.5 -42]);
plot_google_map('maptype','satellite');

%%
I2=imfinfo('../orig_RP/IMG_2419.JPG')
%%
g_rect('g_rect_paramsi1.dat',7)

% print -dpng FishFarmPlume2_raw
%%

clf;set(gcf,'color','w');

g_viz_geodetic( {'../proc/IMG_2419_grect.mat'},...
    'axislimits',[-72-26.4/60 -72-25/60 -42-23./60 -42-22.0/60],'raw',true,'showtime',1);

addpath /ocean/rich/home/metro/drifters/matlab/zoharby-plot_google_map-f73f0ce/
plot_google_map('maptype','satellite','alpha',.5,'mapscale',1,'scalelocation','sw');

axdeg('x');axdeg('y');
set(gca,'linewi',2);
title(['Weird Streaks from fishfarm and Sardine(?) schools   ' get(get(gca,'title'),'string')],'fontsize',14);

% print -dpng FishFarmPlume2

