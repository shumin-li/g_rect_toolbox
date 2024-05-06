function PHOT=readexiftooloutput(fname)
% 
% Get info from the photos using exiftool
%  exiftool -r -n -all -csv *.JPG > metadata.csv

%
%   -n for no formatting, all tags starting with Gimbal or GPS, or
%   containing Altitude:
%        exiftool -csv -r -n -DateTimeOriginal -FOV "-Gimbal*" -"*Altitude*" "-GPS*"  *.JPG   > metadata2.csv

% Path to rd_csv
addpath /ocean/rich/home/metro/ecbuoy/matlab

[C,D]=rd_csv(fname);

iDate=strcmp(C(1,:),'DateTimeOriginal');
iSRC=strcmp(C(1,:),'SourceFile');
iLAT=strcmp(C(1,:),'GPSLatitude');
iLON=strcmp(C(1,:),'GPSLongitude');
iGalt=strcmp(C(1,:),'GPSAltitude');
iRalt=strcmp(C(1,:),'RelativeAltitude');
ipitch=strcmp(C(1,:),'GimbalPitchDegree');
iroll=strcmp(C(1,:),'GimbalRollDegree');
iyaw=strcmp(C(1,:),'GimbalYawDegree');
iFOV=strcmp(C(1,:),'FOV');
iDzm=strcmp(C(1,:),'DigitalZoomRatio');

% Zoom factor is applied to focal length, but I want field of view
FOV=D(2:end,iFOV);
ZmFac=D(2:end,iDzm);
FOV2=2*atand(tand(FOV/2)./ZmFac);

PHOT=struct('mtime',datenum(C(2:end,iDate),'yyyy:mm:dd HH:MM:SS'),...
            'name',{C(2:end,iSRC)},...
             'GPSlat',D(2:end,iLAT),...
             'GPSlon',D(2:end,iLON),...
             'GPSalt',D(2:end,iGalt),...
             'alt',D(2:end,iRalt),...
             'GIMBALpitch',D(2:end,ipitch),...
             'GIMBALroll',D(2:end,iroll),...
             'GIMBALyaw',D(2:end,iyaw),...
             'FOV',FOV2);   % FOV modified by digital zoom
         
