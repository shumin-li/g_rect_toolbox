% UBC test flight

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

%DJI=readflightrecord('../DJIFlightRecord_2023-02-02_[13-57-55].csv','dji');
DJI=readflightrecord('../calibration/23Feb17_Thunderbird/flight_records/csv/FlightRecord_flight_1.csv','dji');

%%
[C,D]=rd_csv('../metadata2.csv');
PHOT=struct('mtime',datenum(C(2:end,excelcol('b')),'yyyy:mm:dd HH:MM:SS'),...
            'name',{C(2:end,1)},...
             'GPSlat',D(2:end,excelcol('r')),...
             'GPSlon',D(2:end,excelcol('s')),...
             'GPSalt',D(2:end,excelcol('l')),...
             'alt',D(2:end,excelcol('k')),...
             'GIMBALpitch',D(2:end,excelcol('f')),...
             'GIMBALroll',D(2:end,excelcol('d')),...
             'GIMBALyaw',D(2:end,excelcol('e')));
         
 % Compare to find OSD-Gimbal yaw = 7 degrees.
 %      Phot Alt needs +51;
 
 %%
 
 PHOT=readexiftooloutput('../calibration/23Feb17_Thunderbird/flight_1/metadata.csv')
 
 %%
 
 g_rect('g_rect_params_UBC.dat',1,'gui');
 
 %%
 
 [hf,hi]=g_viz_geodetic( {'../proc/DJI_0468_grect.mat','../proc/DJI_0466_grect.mat',...
     '../proc/DJI_0419_grect.mat','../proc/DJI_0393_grect.mat'},...
    'axislimits',[-123-18/60 -123-15/60 49+14.75/60 49+16.3/60],'raw',true);

addpath /ocean/rich/home/metro/drifters/matlab/zoharby-plot_google_map-f73f0ce/
plot_google_map('maptype','satellite','mapscale',1);
axdeg('x');axdeg('y');
set(gca,'linewi',2);
 
%%
Aval=.8;
for k=1:length(hi)
    AD=get(hi(k),'alphadata');
    mA=max(AD(:));
    set(hi(k),'alphadata',AD/mA*Aval);
end

%%

g_rect('g_rect_params_UBCtb.dat',3,'gui');

load TBC3
m_line(ncst(:,1),ncst(:,2),'marker','o','color','c','linest','-');

%% Interpolate more points into grid (so pincushion correction works)

load TBC3.mat

ncsto=ncst;
d=cumsum([0;sqrt(diff(ncsto(:,1)*111e3*cosd(49)).^2+diff(ncsto(:,2)*111e3).^2)]);

nd=sort([linspace(0,max(d),max(d))';d]);
ncst=[interp1(d,ncsto(:,1),nd) interp1(d,ncsto(:,2),nd)];
    
save TBC4 ncst



%% Bamfield23

g_rect('g_rect_params_Bamfield23.dat',10,'gui');

%%

figure(2);clf;
 [hf,hi]=g_viz_geodetic( {'../proc/DJI_0594_grect.mat','../proc/DJI_0595_grect.mat',...
     '../proc/DJI_0596_grect.mat','../proc/DJI_0597_grect.mat','../proc/DJI_0599_grect.mat'},...
    'axislimits',[-125-9/60 -125-8/60 48+50/60 48+50.8/60],'raw',true,'Nval',2000);

%%
figure(3);
clf;
for k=1:length(hi)
   A=get(hi(k),'cdata');
   for l=1:3
      subplot(length(hi),3,(k-1)*3+l);
      imhist(squeeze(A(:,:,l)));
   end
end


%%
for k=1:length(hi)
  A=get(hi(k),'cdata');
  A2=imadjust(A,[.5 .5 .5;.8 .9 .9],[0 1]);
  set(hi(k),'cdata',A2);
end

%%
addpath /ocean/rich/home/metro/drifters/matlab/zoharby-plot_google_map-f73f0ce/
plot_google_map('maptype','satellite','mapscale',1);
axdeg('x');axdeg('y');
set(gca,'linewi',2);

% print -dpng Bamfield23_lookingout

%%
[hf,hi]=g_viz_geodetic({'../proc/DJI_0596_grect.mat'},...
    'axislimits',[-125-8.75/60 -125-8/60 48+50.3/60 48+50.8/60],'raw',true,'Nval',5000);

I=rgb2gray(get(hi,'cdata'));

%%
N=250;

fun=@(bs) abs(fftshift(fft2(((hamming(N)*hamming(N)').*(bs.data-mean(mean(bs.data)))))));
B=blockproc(double(I),[N N],fun);
%
%x=[1:5000];y=[1:5000]';k=2*pi./[20 10];k2=2*pi./[10 10];W=sin(k(1)*x+k(2)*y)+.5*sin(k2(1)*x+k2(2)*y);
%B=blockproc(W,[250 250],fun);

clf;
ax(1)=subplot(2,2,1);
imagesc(I);
[X,Y]=meshgrid([0:250:5000],[0:250:5000]);
line(X,Y,'color','w');
line(X',Y','color','w');
colormap(gca,gray);
set(gca,'ydir','normal');
ax(2)=subplot(2,2,2);
imagesc(log10((B)))
set(gca,'ydir','normal');
colormap(gca,m_colmap('jet'));
caxis([2 5]);
line(X,Y,'color','w');
line(X',Y','color','w');
[X,Y]=meshgrid([126:250:5000],[126:250:5000]);
line(X,Y,'color','w','linest','--');
line(X',Y','color','w','linest','--');

subplot(2,1,2);

spc=B([126:250]+250,2750+125+[-10:10]);
loglog([0:124],spc,[0:124],1e10*[0:124].^(-4));
%semilogy(B(:,2750+125+[-10:10]));

linkaxes(ax);



%%

 g_rect('g_rect_params_UBCtb_Mar17.dat',1,'gui');

 %%
 [hf,hi]=g_viz_geodetic( {'../proc/DJI_0649_grect.mat','../proc/DJI_0651_grect.mat',...
     '../proc/DJI_0652_grect.mat','../proc/DJI_0656_grect.mat'},...
    'axislimits',[-123-20/60 -123-12/60 49+12/60 49+18/60],'raw',false,'Nval',2000);

%%
for k=1:length(hi)
  A=get(hi(k),'cdata');
  A2=imadjust(A,[.5 .5 .5;.8 .9 .9],[0 1]);
  set(hi(k),'cdata',A2);
end

%%
addpath /ocean/rich/home/metro/drifters/matlab/zoharby-plot_google_map-f73f0ce/
plot_google_map('maptype','satellite','mapscale',1);
axdeg('x');axdeg('y');
set(gca,'linewi',2);

% print -dpng UBC_lookingout



%% TREX
g_rect('g_rectTREX.dat',2,'gui');

%%
[hf,hi]=g_viz_geodetic( {'../proc/HYPERLAPSE_0162_grect.mat'},...
    'axislimits',[-68.81 -68.797 48.482 48.4941],'raw',false,'Nval',2000);
title('Time: 2020:09:11 09:58:02');

% Image adjustment - pump up all the colours, but especially the red.
A=get(hi,'cdata');
A2=imadjust(A,[0 0 0;.3 .5 .5],[0 1],.5);
set(hi,'cdata',A2);

% COR=load('/ocean/rich/home/metro/drifters/TREX2/Cedric/CoriolisTrack.mat');
% ii=COR.mtime<datenum(2021,09,05,14,05,58)+30/1440 & COR.mtime>datenum(2021,09,05,14,05,58)-30/1440;
% m_line(COR.lon(ii),COR.lat(ii),'color','r');
% 
% load('/ocean/rich/home/metro/drifters/TREX2/gps/gps_FJ.mat');
% ii=FJ.mtime<datenum(2021,09,05,14,05,58)+30/1440 & FJ.mtime>datenum(2021,09,05,14,05,58)-30/1440;
% m_line(FJ.long(ii),FJ.lat(ii),'color','r');

% load('/ocean/rich/home/metro/drifters/TREX2/gps/gps_Mordax.mat');
 ii=Mrdx.mtime-4/24<datenum(2020,09,11,09,58,2)+.75/1440 & Mrdx.mtime-4/24>datenum(2020,09,11,09,58,2)-.75/1440;
 m_line(Mrdx.long(ii),Mrdx.lat(ii),'color','r','linewi',2);



% print -dpng TREX_DyePatch
