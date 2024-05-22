function DJI=readflightrecord(flnam,typ)
% READFLIGHTRECORD reads a DJI flight record file
%

% RP Jan/2023

if nargin<2
    typ='iphone'
end

if ~iscell(flnam)
    flnam={flnam};
end

% addpath /ocean/rich/home/metro/ecbuoy/matlab

fprintf('Reading %s\n',flnam{1});
[A,B]=rd_csv(flnam{1},'headerlines',1);
%C=A;D=B;

iDate=strcmp(A(1,:),'CUSTOM.date [local]');
iTime=strcmp(A(1,:),'CUSTOM.updateTime [local]');
iLAT=strcmp(A(1,:),'OSD.latitude');
iLON=strcmp(A(1,:),'OSD.longitude');
iHeight=strcmp(A(1,:),'OSD.height [ft]');
ivHeight=strcmp(A(1,:),'OSD.vpsHeight [ft]');
iAlt=strcmp(A(1,:),'OSD.altitude [ft]');
iGalt=strcmp(A(1,:),'GPSAltitude');
iOpitch=strcmp(A(1,:),'OSD.pitch');
iOroll=strcmp(A(1,:),'OSD.roll');
iOyaw=strcmp(A(1,:),'OSD.yaw');
igpsnum=strcmp(A(1,:),'OSD.gpsNum');
iBV=strcmp(A(1,:),'BATTERY.voltage [V]');
iBC=strcmp(A(1,:),'BATTERY.current [A]');
iGpitch=strcmp(A(1,:),'GIMBAL.pitch');
iGroll=strcmp(A(1,:),'GIMBAL.roll');
iGyaw=strcmp(A(1,:),'GIMBAL.yaw');
iGLAT=strcmp(A(1,:),'APPGPS.latitude');
iGLON=strcmp(A(1,:),'APPGPS.longitude');
 

switch typ
    case 'iphone'
        DJI=struct('mtime',datenum(A(2:end,iDate),'mm/dd/yyyy')+datenum(A(2:end,iTime),'HH:MM:SS.FFF PM')-datenum(2023,1,1),...
                  'OSDlat',B(2:end,iLAT),...
                  'OSDlon',B(2:end,iLON),...
                  'OSDheight',B(2:end,iHeight)/3.28,...
                  'OSDvpsheight',B(2:end,ivHeight)/3.28,...
                  'OSDaltitude',B(2:end,iAlt)/3.28,...
                  'OSDpitch',B(2:end,iOpitch),...
                  'OSDroll',B(2:end,iOroll),...
                  'OSDyaw',B(2:end,iOyaw),...
                  'OSDgpsnum',B(2:end,igpsnum),...
                  'battV',B(2:end,iBV),....  % V
                  'battC',B(2:end,iBC),...    % A
                  'GIMBALpitch',B(2:end,iGpitch),...
                  'GIMBALroll',B(2:end,iGroll),...
                  'GIMBALyaw',B(2:end,iGyaw),...
                  'GPSlat',B(2:end,iGLAT),...
                  'GPSlon',B(2:end,iGLON) );

         for k=2:length(flnam)
            fprintf('Reading %s\n',flnam{k});
            [A,B]=rd_csv([fls(k).folder,'/',fls(k).name],'headerlines',1);
            DJI.mtime=[DJI.mtime;NaN;datenum(A(2:end,iDate),'mm/dd/yyyy')+datenum(A(2:end,iTime),'HH:MM:SS.FFF PM')-datenum(2023,1,1)];
            DJI.OSDlat=[DJI.OSDlat;B(1:end,iLAT)];
            DJI.OSDlon=[DJI.OSDlon;B(1:end,iLON)];
            DJI.OSDheight=[DJI.OSDheight;B(:,iHeight)/3.28];
            DJI.OSDvpsheight=[DJI.OSDvpsheight;B(:,ivHeight)/3.28];
            DJI.OSDaltitude=[DJI.OSDaltitude;B(:,iAlt)/3.28];
            DJI.OSDpitch=[DJI.OSDpitch;B(1:end,iOpitch)];
            DJI.OSDroll=[DJI.OSDroll;B(1:end,iOroll)];
            DJI.OSDyaw=[DJI.OSDyaw;B(1:end,iOyaw)];
            DJI.OSDgpsnum=[DJI.OSDgpsnum;B(1:end,igpsnum)];
            DJI.battV=[DJI.battV;B(1:end,iBV)];
            DJI.battC=[DJI.battC;B(1:end,iBC)];
            DJI.GIMBALpitch=[DJI.GIMBALpitch;B(:,iGpitch)];
            DJI.GIMBALroll=[DJI.GIMBALroll;B(1:end,iGroll)];
            DJI.GIMBALyaw=[DJI.GIMBALyaw;B(1:end,iGyaw)];
            DJI.GPSlat=[DJI.GPSlat;B(1:end,iGLAT)];
            DJI.GPSlon=[DJI.GPSlon;B(1:end,iGLON)];
         end
    case 'dji'
            DJI=struct('mtime',datenum(A(2:end,excelcol('c')),'mm/dd/yyyy')+datenum(A(2:end,excelcol('d')),'HH:MM:SS.FFF PM')-datenum(2023,1,1),...
                  'OSDlat',B(2:end,excelcol('g')),...
                  'OSDlon',B(2:end,excelcol('h')),...
                  'OSDheight',B(2:end,excelcol('i'))/3.28,...
                  'OSDvpsheight',B(2:end,excelcol('k'))/3.28,...
                  'OSDaltitude',B(2:end,excelcol('l'))/3.28,...
                  'OSDpitch',B(2:end,excelcol('v')),...
                  'OSDroll',B(2:end,excelcol('w')),...
                  'OSDyaw',B(2:end,excelcol('x')),...
                  'OSDgpsnum',B(2:end,excelcol('ac')),...
                  'battV',B(2:end,excelcol('ck')),....  % V
                  'battC',B(2:end,excelcol('cu')),...    % A
                  'GIMBALpitch',B(2:end,excelcol('bf')),...
                  'GIMBALroll',B(2:end,excelcol('bg')),...
                  'GIMBALyaw',B(2:end,excelcol('bh')), ...
                  'GPSlat',B(2:end,excelcol('g')),...  % Repeat
                  'GPSlon',B(2:end,excelcol('h'))  );

         for k=2:length(flnam)
            fprintf('Reading %s\n',flnam{k});
            [A,B]=rd_csv([fls(k).folder,'/',fls(k).name],'headerlines',1);
            DJI.mtime=[DJI.mtime;NaN;datenum(A(2:end,excelcol('c')),'mm/dd/yyyy')+datenum(A(2:end,excelcol('d')),'HH:MM:SS.FFF PM')-datenum(2023,1,1)];
            DJI.OSDlat=[DJI.OSDlat;B(1:end,excelcol('g'))];
            DJI.OSDlon=[DJI.OSDlon;B(1:end,excelcol('h'))];
            DJI.OSDheight=[DJI.OSDheight;B(:,excelcol('i'))/3.28];
            DJI.OSDvpsheight=[DJI.OSDvpsheight;B(:,excelcol('k'))/3.28];
            DJI.OSDaltitude=[DJI.OSDaltitude;B(:,excelcol('l'))/3.28];
            DJI.OSDpitch=[DJI.OSDpitch;B(1:end,excelcol('v'))];
            DJI.OSDroll=[DJI.OSDroll;B(1:end,excelcol('w'))];
            DJI.OSDyaw=[DJI.OSDyaw;B(1:end,excelcol('x'))];
            DJI.OSDgpsnum=[DJI.OSDgpsnum;B(1:end,excelcol('ac'))];
            DJI.battV=[DJI.battV;B(1:end,excelcol('cu'))];
            DJI.battC=[DJI.battC;B(1:end,excelcol('ck'))];
            DJI.GIMBALpitch=[DJI.GIMBALpitch;B(:,excelcol('bf'))];
            DJI.GIMBALroll=[DJI.GIMBALroll;B(1:end,excelcol('bg'))];
            DJI.GIMBALyaw=[DJI.GIMBALyaw;B(1:end,excelcol('h'))];
            DJI.GPSlat=[DJI.GPSlat;B(1:end,excelcol('g'))];
            DJI.GPSlon=[DJI.GPSlon;B(1:end,excelcol('h'))];

         end    
end
