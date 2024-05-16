%% sl_readphotometa
function PHOT = sl_readphotometa(flnam)


if ~iscell(flnam)
    flnam={flnam};
end

for k = 1:numel(flnam)
fprintf('Reading %s\n',flnam{k});

%% Import data from text file


% flnam = {'/Users/shuminli/g_rect_toolbox/sl_matlab/test_read_csv/photo_meta/meta_PRODIGY24.csv'};

% define readtable options
opts = delimitedTextImportOptions("Encoding", "UTF-8");
opts.DataLines = [2, Inf];
opts.Delimiter = ",";

% opts_vns -- to get Variable Names
opts_vns = delimitedTextImportOptions("Encoding", "UTF-8");
opts_vns.DataLines = [1, 1];
opts_vns.Delimiter = ",";

% Import the data
this_table = readtable(flnam{k}, opts); % read everthing as text
vns = table2cell(readtable(flnam{k}, opts_vns)); % get table variables
this_table.Properties.VariableNames = vns; % read table variables


%Clear temporary variables
clear opts opts_vns 

%% making data structure DJI


formatIn = 'yyyy:MM:dd HH:mm:ssZ';
local_datetime = datetime(this_table.FileModifyDate,'InputFormat',formatIn,'TimeZone','America/Vancouver');
local_mtime = datenum(local_datetime);


% 'SourceFile',this_table.SourceFile,...
%     'name',this_table.FileName,...

if k == 1

    
PHOT=struct('mtime',local_mtime,...
    'datetime',local_datetime,...
    'timezone','America/Vancouver',...
    'SourceFile',{this_table.SourceFile},...
    'name',{this_table.FileName},...
    'ExposureTime', str2double(this_table.ExposureTime),...
    'FNumber', str2double(this_table.FNumber),...
    'ISO', str2double(this_table.ISO),...
    'ShutterSpeedValue', str2double(this_table.ShutterSpeedValue),...
    'ApertureValue', str2double(this_table.ApertureValue),...
    'FocalLength', str2double(this_table.FocalLength),...
    'FocalLengthIn35mmFormat', str2double(this_table.FocalLengthIn35mmFormat),...
    'DigitalZoomRatio', str2double(this_table.DigitalZoomRatio),...
    'GPSMapDatum',{this_table.GPSMapDatum},...
    'AbsoluteAltitude',str2double(this_table.AbsoluteAltitude),...
    'RelativeAltitude',str2double(this_table.RelativeAltitude),...
    'GPSAltitude',str2double(this_table.GPSAltitude),...
    'GPSlat',str2double(this_table.GPSLatitude),...
    'GPSlon',str2double(this_table.GPSLongitude),...
    'FOV',str2double(this_table.FOV),...
    'GIMBALpitch',str2double(this_table.GimbalPitchDegree),...
    'GIMBALroll',str2double(this_table.GimbalRollDegree),...
    'GIMBALyaw',str2double(this_table.GimbalYawDegree), ...
    'OSDpitch',str2double(this_table.FlightPitchDegree),...
    'OSDroll',str2double(this_table.FlightRollDegree),...
    'OSDyaw',str2double(this_table.FlightYawDegree),...
    'FlightXSpeed',str2double(this_table.FlightXSpeed),...
    'FlightYSpeed',str2double(this_table.FlightYSpeed),...
    'FlightZSpeed',str2double(this_table.FlightZSpeed),...
    'LightValue',str2double(this_table.LightValue)); % 


else
    

    PHOT.mtime = [PHOT.mtime; local_mtime];
    PHOT.datetime = [PHOT.datetime; local_datetime];
    PHOT.SourceFile = [PHOT.SourceFile; this_table.SourceFile];
    PHOT.name = [PHOT.name; this_table.FileName];
    PHOT.ExposureTime = [PHOT.ExposureTime; str2double(this_table.ExposureTime)];
    PHOT.FNumber = [PHOT.FNumber; str2double(this_table.FNumber)];
    PHOT.ISO = [PHOT.ISO; str2double(this_table.ISO)];
    PHOT.ShutterSpeedValue = [PHOT.ShutterSpeedValue; str2double(this_table.ShutterSpeedValue)];
    PHOT.ApertureValue = [PHOT.ApertureValue; str2double(this_table.ApertureValue)];
    PHOT.FocalLength = [PHOT.FocalLength; str2double(this_table.FocalLength)];
    PHOT.FocalLengthIn35mmFormat = [PHOT.FocalLengthIn35mmFormat; str2double(this_table.FocalLengthIn35mmFormat)];
    PHOT.DigitalZoomRatio = [PHOT.DigitalZoomRatio; str2double(this_table.DigitalZoomRatio)];
    PHOT.GPSMapDatum = [PHOT.GPSMapDatum; this_table.GPSMapDatum];
    PHOT.AbsoluteAltitude = [PHOT.AbsoluteAltitude; str2double(this_table.AbsoluteAltitude)];
    PHOT.RelativeAltitude = [PHOT.RelativeAltitude; str2double(this_table.RelativeAltitude)];
    PHOT.GPSAltitude = [PHOT.GPSAltitude; str2double(this_table.GPSAltitude)];
    PHOT.GPSlat = [PHOT.GPSlat; str2double(this_table.GPSLatitude)];
    PHOT.GPSlon = [PHOT.GPSlon; str2double(this_table.GPSLongitude)];
    PHOT.FOV = [PHOT.FOV; str2double(this_table.FOV)];
    PHOT.GIMBALpitch = [PHOT.GIMBALpitch; str2double(this_table.GimbalPitchDegree)];
    PHOT.GIMBALroll = [PHOT.GIMBALroll; str2double(this_table.GimbalRollDegree)];
    PHOT.GIMBALyaw = [PHOT.GIMBALyaw; str2double(this_table.GimbalYawDegree)];
    PHOT.OSDpitch = [PHOT.OSDpitch; str2double(this_table.FlightPitchDegree)];
    PHOT.OSDroll = [PHOT.OSDroll; str2double(this_table.FlightRollDegree)];
    PHOT.OSDyaw = [PHOT.OSDyaw; str2double(this_table.FlightYawDegree)];
    PHOT.FlightXSpeed = [PHOT.FlightXSpeed; str2double(this_table.FlightXSpeed)];
    PHOT.FlightYSpeed = [PHOT.FlightYSpeed; str2double(this_table.FlightYSpeed)];
    PHOT.FlightZSpeed = [PHOT.FlightZSpeed; str2double(this_table.FlightZSpeed)];
    PHOT.LightValue = [PHOT.LightValue; str2double(this_table.LightValue)];

end


end