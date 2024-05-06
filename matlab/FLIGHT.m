% Flight path stuff
% Flight records processing: tutorial:
% https://www.phantomhelp.com/tips/how-to-retrieve-dji-go-flight-logs-from-itunes.29
% website:
% https://www.phantomhelp.com/LogViewer/upload/


addpath /ocean/rich/home/metro/ecbuoy/matlab

[A,B]=rd_csv('../drone_SL/DJIFlightRecord_2023-01-10_[09-07-17].csv','headerlines',1);

%%
fls=dir('../drone_SL/flightrecords/*.csv');

[A,B]=rd_csv([fls(1).folder,'/',fls(1).name],'headerlines',1);

DJI=struct('mtime',datenum(A(2:end,1),'mm/dd/yyyy')+datenum(A(2:end,2),'HH:MM:SS.FFF PM')-datenum(2023,1,1),...
          'OSDlat',B(2:end,5),...
          'OSDlon',B(2:end,6),...
          'OSDheight',B(2:end,7)/3.28,...
          'OSDvpsheight',B(2:end,9)/3.28,...
          'OSDaltitude',B(2:end,10)/3.28,...
          'OSDpitch',B(2:end,20),...
          'OSDroll',B(2:end,21),...
          'OSDyaw',B(2:end,22),...
          'OSDgpsnum',B(2:end,27),...
          'battV',B(2:end,90),....  % V
          'battC',B(2:end,97),...    % A
          'GIMBALpitch',B(2:end,56),...
          'GIMBALroll',B(2:end,57),...
          'GIMBALyaw',B(2:end,58),...
          'GPSlat',B(2:end,179),...
          'GPSlon',B(2:end,180) );
  
 for k=2:length(fls)
    fprintf('Reading %s\n',fls(k).name);
    [A,B]=rd_csv([fls(k).folder,'/',fls(k).name],'headerlines',1);
    DJI.mtime=[DJI.mtime;NaN;datenum(A(2:end,1),'mm/dd/yyyy')+datenum(A(2:end,2),'HH:MM:SS.FFF PM')-datenum(2023,1,1)];
    DJI.OSDlat=[DJI.OSDlat;B(1:end,5)];
    DJI.OSDlon=[DJI.OSDlon;B(1:end,6)];
    DJI.OSDheight=[DJI.OSDheight;B(:,7)/3.28];
    DJI.OSDvpsheight=[DJI.OSDvpsheight;B(:,9)/3.28];
    DJI.OSDaltitude=[DJI.OSDaltitude;B(:,10)/3.28];
    DJI.OSDpitch=[DJI.OSDpitch;B(1:end,20)];
    DJI.OSDroll=[DJI.OSDroll;B(1:end,21)];
    DJI.OSDyaw=[DJI.OSDyaw;B(1:end,22)];
    DJI.OSDgpsnum=[DJI.OSDgpsnum;B(1:end,27)];
    DJI.battV=[DJI.battV;B(1:end,90)];
    DJI.battC=[DJI.battC;B(1:end,97)];
    DJI.GIMBALpitch=[DJI.GIMBALpitch;B(:,56)];
    DJI.GIMBALroll=[DJI.GIMBALroll;B(1:end,57)];
    DJI.GIMBALyaw=[DJI.GIMBALyaw;B(1:end,58)];
    DJI.GPSlat=[DJI.GPSlat;B(1:end,179)];
    DJI.GPSlon=[DJI.GPSlon;B(1:end,180)];
 end
      
% save DJIflight DJI

 %%     
 [C,D]=rd_csv('../drone_SL/metadata2.csv');

 PHOT=struct('mtime',datenum(C(2:end,2),'yyyy:mm:dd HH:MM:SS')-2/24,...
             'GPSlat',D(2:end,19),...
             'GPSlon',D(2:end,20),...
             'GPSalt',D(2:end,13),...
             'alt',D(2:end,12),...
             'GIMBALpitch',D(2:end,7),...
             'GIMBALroll',D(2:end,5),...
             'GIMBALyaw',D(2:end,6));
             
% save DJIphot PHOT

%%

PHOT=readexiftooloutput('../calibration/Huinay_delta/metadata.csv')
DJI=readflightrecord('../calibration/Huinay_delta/DJIFlightRecord_2023-01-04_[06-49-43].csv','dji');

%%

%PHOT=readexiftooloutput('/ocean/shuminli/DJI/23Mar17_Thunderbird_mini3Pro/mapping/metadata_mapping.csv')
PHOT=readexiftooloutput('/ocean/shuminli/DJI/23Mar17_Thunderbird_mini3Pro/metadata_Mar_17_all.csv');
 
DJI=readflightrecord('/ocean/shuminli/DJI/23Mar17_Thunderbird_mini3Pro/flight_records/csv/DJIFlightRecord_2023-03-16_[12-04-18].csv');
DJI.mtime=DJI.mtime-3/24;  % Clock seems off?

%%
ii=PHOT.mtime>DJI.mtime(1)-20/1440 & PHOT.mtime<DJI.mtime(end)+20/1440;

clf;
plot(DJI.OSDlon,DJI.OSDlat,DJI.GPSlon,DJI.GPSlat,'marker','.');
line(PHOT.GPSlon(ii),PHOT.GPSlat(ii),'marker','o','linest','none','color','r');

% Corrected by 29 degrees!
Aiff=29;
 angx=sind(PHOT.GIMBALyaw(ii)'+Aoff)*10/(111e3*cosd(49));angy=cosd(PHOT.GIMBALyaw(ii)'+Aoff)*10/111e3;;
 line([1;1]*PHOT.GPSlon(ii)'+[0;1]*angx,[1;1]*PHOT.GPSlat(ii)'+[0;1]*angy,'linest','-','color','g');

%%
plot(DJI.mtime-3/24,DJI.OSDlat,'.-')
line(PHOT.mtime,PHOT.GPSlat,'marker','o','color','r');
ylim([49.2535 49.2555]);
    axdate;
    
    
%%    Version 1 figure - show all comparable series
ii=find(PHOT.mtime>DJI.mtime(1)-20/1440 & PHOT.mtime<DJI.mtime(end)+20/1440);

Poff=1/86400; % Delay of photo timestamps relative to Drone timestamps.

PM=PHOT.mtime(ii)+Poff;

clf;ax=[];
ax(1)=subplot(7,1,1);
plot(DJI.mtime,DJI.OSDlat,DJI.mtime,DJI.GPSlat,'marker','.');
kk=[logical(1);diff(DJI.mtime)>0];
i2=PHOT.GPSlat(ii)>interp1(DJI.mtime(kk),DJI.GPSlat(kk),PM);
line(PM(i2),PHOT.GPSlat(ii(i2)),'marker','o','linest','none');
line(PM(~i2),PHOT.GPSlat(ii(~i2)),'marker','o','linest','none','color','r');
zaxdate(8,'nolabel');
legend({'OSD','GPS','Phot'});

ax(2)=subplot(7,1,2);
plot(DJI.mtime,DJI.OSDlon,DJI.mtime,DJI.GPSlon,'marker','.');
%line(PHOT.mtime(ii)+Poff,PHOT.GPSlon(ii),'marker','o','linest','none');
kk=[logical(1);diff(DJI.mtime)>0];
i2=PHOT.GPSlon(ii)>interp1(DJI.mtime(kk),DJI.GPSlon(kk),PHOT.mtime(ii)+Poff);
line(PM(i2),PHOT.GPSlon(ii(i2)),'marker','o','linest','none');
line(PM(~i2),PHOT.GPSlon(ii(~i2)),'marker','o','linest','none','color','r');
zaxdate(8,'nolabel');
legend({'OSD','GPS','Phot'});

ax(3)=subplot(7,1,3);
plot(DJI.mtime,DJI.OSDheight,DJI.mtime,DJI.OSDvpsheight,DJI.mtime,DJI.OSDaltitude,'marker','.');
line(PM,PHOT.GPSalt(ii),'marker','o','linest','none');
line(PM,PHOT.alt(ii),'marker','x','linest','none');
legend('OSD','vps(GPS)','OSDaltitude','PhotGPS','Photalt');

zaxdate(8,'nolabel');
ax(4)=subplot(7,1,6);
plot(DJI.mtime,DJI.OSDpitch,DJI.mtime,DJI.GIMBALpitch,'marker','.');
line(PM,PHOT.GIMBALpitch(ii),'marker','o','linest','none');
zaxdate(8,'nolabel');
ylabel('Pitch');
legend({'OSD','GIMBAL','Phot'});

ax(5)=subplot(7,1,5);
plot(DJI.mtime,DJI.OSDroll,DJI.mtime,DJI.GIMBALroll,'marker','.');
line(PM,PHOT.GIMBALroll(ii),'marker','o','linest','none');
zaxdate(8,'nolabel');
ylabel('Roll');
legend({'OSD','GIMBAL','Phot'});

ax(6)=subplot(7,1,4);
plot(DJI.mtime,DJI.OSDyaw,DJI.mtime,DJI.GIMBALyaw,'marker','.');
line(PM,PHOT.GIMBALyaw(ii),'marker','o','linest','none');
zaxdate(8,'nolabel');
ylabel('Yaw');
legend({'OSD','GIMBAL','Phot'});

ax(7)=subplot(7,1,7);
plot(DJI.mtime,DJI.battV,DJI.mtime,DJI.battC,'marker','.');
zaxdate('x',8);
ylabel('Battery Volts/Amps');
legend({'Voltage','Current'});

for k=1:6
    set(ax(k),'pos',get(ax(k),'pos')+[0 0 0 .02],'xgrid','on','ygrid','on');
end
linkaxes(ax,'x');

%% Version 2 figure - compare different yaw and height fields

load DJIflight
load DJIphot

%%

yy=DJI.OSDyaw-DJI.GIMBALyaw;
yy(yy<-180)=yy(yy<-180)+360;
yy(yy>180)=yy(yy>180)-360;
cyy=yy;%clean(yy,13);

% Put all the segments 6 minutes apart so they all fit on one plot.
ib=find(isnan(DJI.mtime));
for ii=1:length(ib)
    chng=-DJI.mtime(ib(ii)+1)+DJI.mtime(ib(ii)-1)+.1/24
    ik=find(PHOT.mtime>DJI.mtime(ib(ii)-1));
    DJI.mtime(ib(ii):end)=DJI.mtime(ib(ii):end)+chng;
    PHOT.mtime(ik)=PHOT.mtime(ik)+chng;
end

ii=find(PHOT.mtime>DJI.mtime(1)-20/1440 & PHOT.mtime<DJI.mtime(end)+20/1440);

Poff=1/86400; % Delay of photo timestamps relative to Drone timestamps.

PM=PHOT.mtime(ii)+Poff;


clf;ax=[];
ax(1)=subplot(4,1,1);
plot(DJI.mtime,DJI.OSDheight,DJI.mtime,DJI.OSDvpsheight,DJI.mtime,DJI.OSDaltitude,'marker','.');
line(PM,PHOT.GPSalt(ii),'marker','o','linest','none');
line(PM,PHOT.alt(ii),'marker','x','linest','none');
zaxdate(8,'nolabel');grid;
legend('height','vpsheight','altitude','PhotGPSalt','Photalt');
ylabel('Heights/m');

ax(2)=subplot(4,1,2);
plot(DJI.mtime,DJI.OSDaltitude-DJI.OSDheight,'marker','.');
line(PM,PHOT.GPSalt(ii)-PHOT.alt(ii),'marker','o','linest','none');
zaxdate(8,'nolabel');grid;
ylabel({'Height diff (altitude-height)','(PHOTGPSalt-PHOTalt)'});

ax(3)=subplot(4,1,3);
plot(DJI.mtime,DJI.OSDyaw,DJI.mtime,DJI.GIMBALyaw,'marker','.');
line(PM,PHOT.GIMBALyaw(ii),'marker','o','linest','none');
zaxdate(8,'nolabel');grid;
legend('OSD','Gimbal','Photo');
ylabel('Yaw');

ax(4)=subplot(4,1,4);
plot(DJI.mtime,yy,'marker','.');
line(DJI.mtime,cyy,'color','r','linewi',2);
[~,i2]=unique(DJI.mtime);
line(PM,interp1(DJI.mtime(i2),DJI.GIMBALyaw(i2),PM)-PHOT.GIMBALyaw(ii),'marker','o','linest','none','linewi',2);
ylabel('Yaw diff (OSD-GIMBAL)');
zaxdate('x',8);grid;
ylim([-2 30]);
legend('(OSD-GIMBAL)','clean (OSD-GIMBAL)','GIMBAL-Photo');


linkaxes(ax,'x');
sgtitle('Yaw and altitude errors');

% print -dpng Yaw_altitude_by_flight




%% REfraction on spherical earth

R=6378e3;  % Earth radius
H=100;     % Observer height

r=5.3*R;  % Refracted curvature radius as a ratio to Earth radius
        % According to Young (2006) the curvature is
        % 5.3 for a 'standard' lapse rate
        % 4.3 for an isothermal atmosphere
        % 6   for a convective atmosphere

        
% Dip of horizon (spherical earth) - Pawlowicz (2003)
sdips=sqrt(2*H/R)*180/pi;
% Distance to horizon (spherical earth)
hLs=sqrt(2*R*H);


% Actual dip to horizon including refraction in standard atmosphere (after French, 1982)
hdipa=sqrt(2*H/R)*(1-.092)*180/pi;
% Actual distance of horizon (after French, 1982)
hLa=sqrt(2*R*H)*(1+.092);

% Actual dip to horizon including refraction in standard atmosphere -
% circular arcs
hdipa=sqrt(2*H/R)*(1-R/(2*r))*180/pi;
% Actual distance of horizon - circular arcs
hLa=sqrt(2*R*H)/(1-R/(2*r));


% Now get dip angles for distances closer than horizon

L=logspace(-1,log10(sqrt(2*R*H)*1.5),1000);  % m
Lk=L/1e3;       % km

fdip=atand(H./L);           % Here L represents the 'flat earth' distance for an angle fdip
sdip=atand(H./L+L/(2*R));   % here L is the 'spherical earth' distance for an angle sdip

       %  for a given spherical distance L, this is the refraction angle 
       %  (decreases dip), so that sdip-alph is the actual dip angle
alph=asind(L/(2*r).*sqrt(1 + (H./L+L/(2*R)).^2));
alph2=(L/(2*r).*sqrt(1 + (H./L+L/(2*R)).^2))*180/pi;


maxang=10;

clf;
subplot(2,1,1);
plot(fdip,Lk,sdip,Lk,sdip-alph,Lk,sdip-alph2,Lk,'--');
line([sdips],hLs/1e3,'linest','none','marker','o','linewi',1.5);
line([hdipa],hLa/1e3,'linest','none','marker','s','linewi',1.5,'color','r');
legend({'Flat Earth','Spherical Earth','Spherical Earth with refraction',...
         'Small angle approx','Spherical Horizon','Refracted Horizon'},'location','northeast');
grid;
ylabel({'Estimated Distance to ground point in km ','associated with a given dip angle'});
xlabel('Dip Angle/^o');
%set(gca,'ydir','reverse');
title(['Distance/Dip relationship: Height of '  num2str(H) 'm']);

axis([0 maxang 0 ceil(hLa/1e4)*10]);

subplot(2,1,2);

% have to come up with the reverse mapping D(angle)
% intead of angle(D) which we calculated above.
angs=linspace(sdips,maxang,1600);

method='makima';
fLI=interp1(fdip,Lk,angs,method);
sLI=interp1(sdip,Lk,angs,method);
refrLI=interp1(sdip-alph,Lk,angs,method);

S2F=sLI./fLI;
R2F=refrLI./fLI;

semilogy(angs,100*(S2F-1),angs,100*(R2F-1));

line(angs,100*.005./fLI,'linest','-.'); % Effect of 5 meter error in distance
                                                
                                                 
line(angs,100*(S2F-1)*(1-R/r),'linest','--','linewi',2); % OK, this is the approximate 
                                              % refractive correction to
                                              % spherical ratios.

axis([0 maxang .1 0.4*100]);
grid;
xlabel('Dip Angle/^o');
ylabel({'Ratio of Distance/Flat Distance','(percent in excess of 100%'});
legend({'Spherical/Flat','Refracted/Flat','5 m error limit','Simple 80% reduction of sphericity'},'location','northeast');


 % print('-dpdf',['RefractionEffects' int2str(H)]);
 
    




