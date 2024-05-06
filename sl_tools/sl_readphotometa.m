%% sl_readphotometa
function PHOT = sl_readphotometa(flnam)


if ~iscell(flnam)
    flnam={flnam};
end

for k = 1:numel(flnam)
fprintf('Reading %s\n',flnam{k});

%% Import data from text file
% Script for importing data from the following text file:
%
%    filename: /Users/shuminli/Documents/research/Drones/rich/calibration/23Feb17_Thunderbird/flight_records/csv/FlightRecord_flight_1.csv
%
% Auto-generated by MATLAB on 25-Apr-2024 12:04:31

opts = delimitedTextImportOptions("NumVariables", 150);

% Specify range and delimiter
opts.DataLines = [2, Inf];
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["SourceFile", "ExifToolVersion", "FileName", "Directory", "FileSize", "FileModifyDate", "FileAccessDate", "FileInodeChangeDate", "FilePermissions", "FileType", "FileTypeExtension", "MIMEType", "ExifByteOrder", "ImageDescription", "Make", "Model", "Orientation", "XResolution", "YResolution", "ResolutionUnit", "Software", "ModifyDate", "YCbCrPositioning", "ExposureTime", "FNumber", "ExposureProgram", "ISO", "SensitivityType", "RecommendedExposureIndex", "ExifVersion", "DateTimeOriginal", "CreateDate", "ComponentsConfiguration", "ShutterSpeedValue", "ApertureValue", "ExposureCompensation", "MaxApertureValue", "MeteringMode", "LightSource", "Flash", "FocalLength", "AEDebugInfo", "AEHistogramInfo", "AELocalHistogram", "AELiveViewHistogramInfo", "AELiveViewLocalHistogram", "AWBDebugInfo", "AFDebugInfo", "Histogram", "Xidiri", "GimbalDegree", "FlightDegree", "ADJDebugInfo", "SensorID", "FlightSpeed", "Sensor_Temperature", "HyperlapsDebugInfo", "FlashpixVersion", "ColorSpace", "ExifImageWidth", "ExifImageHeight", "InteropIndex", "InteropVersion", "FileSource", "SceneType", "ExposureMode", "WhiteBalance", "DigitalZoomRatio", "FocalLengthIn35mmFormat", "SceneCaptureType", "GainControl", "Contrast", "Saturation", "Sharpness", "DeviceSettingDescription", "SerialNumber", "LensInfo", "GPSVersionID", "GPSLatitudeRef", "GPSLongitudeRef", "GPSAltitudeRef", "GpsStatus", "GPSMapDatum", "XPComment", "XPKeywords", "Compression", "ThumbnailOffset", "ThumbnailLength", "About", "Format", "ImageSource", "AltitudeType", "AbsoluteAltitude", "RelativeAltitude", "GimbalRollDegree", "GimbalYawDegree", "GimbalPitchDegree", "FlightRollDegree", "FlightYawDegree", "FlightPitchDegree", "FlightXSpeed", "FlightYSpeed", "FlightZSpeed", "CamReverse", "GimbalReverse", "SelfData", "SurveyingMode", "UTCAtExposure", "ShutterType", "CameraSerialNumber", "LensSerialNumber", "DroneModel", "DroneSerialNumber", "Version", "HasSettings", "HasCrop", "AlreadyApplied", "MPFVersion", "NumberOfImages", "MPImageFlags", "MPImageFormat", "MPImageType", "MPImageLength", "MPImageStart", "DependentImage1EntryNumber", "DependentImage2EntryNumber", "ImageUIDList", "TotalFrames", "ImageWidth", "ImageHeight", "EncodingProcess", "BitsPerSample", "ColorComponents", "YCbCrSubSampling", "Aperture", "ImageSize", "Megapixels", "ScaleFactor35efl", "ShutterSpeed", "ThumbnailImage", "GPSAltitude", "GPSLatitude", "GPSLongitude", "PreviewImage", "CircleOfConfusion", "FOV", "FocalLength35efl", "GPSPosition", "HyperfocalDistance", "LightValue"];
opts.VariableTypes = ["string", "string", "string", "categorical", "double", "datetime", "datetime", "datetime", "double", "categorical", "categorical", "categorical", "categorical", "categorical", "categorical", "double", "double", "double", "double", "double", "categorical", "string", "double", "double", "double", "double", "double", "double", "double", "double", "string", "string", "categorical", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "string", "string", "double", "categorical", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "categorical", "categorical", "categorical", "categorical", "categorical", "double", "categorical", "double", "categorical", "categorical", "double", "double", "double", "categorical", "categorical", "categorical", "categorical", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "string", "double", "string", "categorical", "categorical", "string", "double", "categorical", "double", "categorical", "categorical", "categorical", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "categorical", "double", "categorical", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "string", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["SourceFile", "ExifToolVersion", "FileName", "ModifyDate", "DateTimeOriginal", "CreateDate", "GimbalDegree", "FlightDegree", "SelfData", "UTCAtExposure", "LensSerialNumber", "GPSPosition"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["SourceFile", "ExifToolVersion", "FileName", "Directory", "FileType", "FileTypeExtension", "MIMEType", "ExifByteOrder", "ImageDescription", "Make", "Software", "ModifyDate", "DateTimeOriginal", "CreateDate", "ComponentsConfiguration", "GimbalDegree", "FlightDegree", "SensorID", "SerialNumber", "LensInfo", "GPSVersionID", "GPSLatitudeRef", "GPSLongitudeRef", "GpsStatus", "XPComment", "XPKeywords", "About", "Format", "ImageSource", "AltitudeType", "SelfData", "UTCAtExposure", "ShutterType", "CameraSerialNumber", "LensSerialNumber", "DroneSerialNumber", "HasSettings", "HasCrop", "AlreadyApplied", "YCbCrSubSampling", "ImageSize", "GPSPosition"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, "FileModifyDate", "InputFormat", "yyyy:MM:dd HH:mm:ssZ","timezone","UTC");
opts = setvaropts(opts, "FileAccessDate", "InputFormat", "yyyy:MM:dd HH:mm:ssZ","timezone","UTC");
opts = setvaropts(opts, "FileInodeChangeDate", "InputFormat", "yyyy:MM:dd HH:mm:ssZ","timezone","UTC");
opts = setvaropts(opts, ["Model", "AEDebugInfo", "AEHistogramInfo", "AELocalHistogram", "AELiveViewHistogramInfo", "AELiveViewLocalHistogram", "AWBDebugInfo", "AFDebugInfo", "Histogram", "Xidiri", "ADJDebugInfo", "FlightSpeed", "Sensor_Temperature", "HyperlapsDebugInfo", "InteropIndex", "DeviceSettingDescription", "GPSMapDatum", "DroneModel", "ImageUIDList", "ThumbnailImage", "PreviewImage"], "TrimNonNumeric", true);
opts = setvaropts(opts, ["Model", "AEDebugInfo", "AEHistogramInfo", "AELocalHistogram", "AELiveViewHistogramInfo", "AELiveViewLocalHistogram", "AWBDebugInfo", "AFDebugInfo", "Histogram", "Xidiri", "ADJDebugInfo", "FlightSpeed", "Sensor_Temperature", "HyperlapsDebugInfo", "InteropIndex", "DeviceSettingDescription", "GPSMapDatum", "DroneModel", "ImageUIDList", "ThumbnailImage", "PreviewImage"], "ThousandsSeparator", ",");

% Import the data
this_table = readtable(flnam{k}, opts);


%Clear temporary variables
clear opts

%% making data structure DJI

% m2f = 3.28084;


if k == 1
PHOT=struct('mtime',datenum(this_table.FileModifyDate),...
    'timezone','UTC',...
    'SourceFile',this_table.SourceFile,...
    'name',this_table.FileName,...
    'ExposureTime', this_table.ExposureTime,...
    'FNumber', this_table.FNumber,...
    'ISO', this_table.ISO,...
    'ShutterSpeedValue', this_table.ShutterSpeedValue,...
    'ApertureValue', this_table.ApertureValue,...
    'FocalLength', this_table.FocalLength,...
    'FocalLengthIn35mmFormat', this_table.FocalLengthIn35mmFormat,...
    'DigitalZoomRatio', this_table.DigitalZoomRatio,...
    'GPSMapDatum',this_table.GPSMapDatum,...
    'AbsoluteAltitude',this_table.AbsoluteAltitude,...
    'RelativeAltitude',this_table.RelativeAltitude,...
    'GPSAltitude',this_table.GPSAltitude,...
    'GPSlat',this_table.GPSLatitude,...
    'GPSlon',this_table.GPSLongitude,...
    'FOV',this_table.FOV,...
    'GIMBALpitch',this_table.GimbalPitchDegree,...
    'GIMBALroll',this_table.GimbalRollDegree,...
    'GIMBALyaw',this_table.GimbalYawDegree, ...
    'OSDpitch',this_table.FlightPitchDegree,...
    'OSDroll',this_table.FlightRollDegree,...
    'OSDyaw',this_table.FlightYawDegree,...
    'FlightXSpeed',this_table.FlightXSpeed,...
    'FlightYSpeed',this_table.FlightYSpeed,...
    'FlightZSpeed',this_table.FlightZSpeed,...
    'LightValue',this_table.LightValue); % 

else
    

    PHOT.mtime = [PHOT.mtime; datenum(this_table.FileModifyDate)];
    PHOT.SourceFile = [PHOT.SourceFile; this_table.SourceFile];
    PHOT.name = [PHOT.name; this_table.FileName];
    PHOT.ExposureTime = [PHOT.ExposureTime; this_table.ExposureTime];
    PHOT.FNumber = [PHOT.FNumber; this_table.FNumber];
    PHOT.ISO = [PHOT.ISO; this_table.ISO];
    PHOT.ShutterSpeedValue = [PHOT.ShutterSpeedValue; this_table.ShutterSpeedValue];
    PHOT.ApertureValue = [PHOT.ApertureValue; this_table.ApertureValue];
    PHOT.FocalLength = [PHOT.FocalLength; this_table.FocalLength];
    PHOT.FocalLengthIn35mmFormat = [PHOT.FocalLengthIn35mmFormat; this_table.FocalLengthIn35mmFormat];
    PHOT.DigitalZoomRatio = [PHOT.DigitalZoomRatio; this_table.DigitalZoomRatio];
    PHOT.GPSMapDatum = [PHOT.GPSMapDatum; this_table.GPSMapDatum];
    PHOT.AbsoluteAltitude = [PHOT.AbsoluteAltitude; this_table.AbsoluteAltitude];
    PHOT.RelativeAltitude = [PHOT.RelativeAltitude; this_table.RelativeAltitude];
    PHOT.GPSAltitude = [PHOT.GPSAltitude; this_table.GPSAltitude];
    PHOT.GPSlat = [PHOT.GPSlat; this_table.GPSLatitude];
    PHOT.GPSlon = [PHOT.GPSlon; this_table.GPSLongitude];
    PHOT.FOV = [PHOT.FOV; this_table.FOV];
    PHOT.GIMBALpitch = [PHOT.GIMBALpitch; this_table.GimbalPitchDegree];
    PHOT.GIMBALroll = [PHOT.GIMBALroll; this_table.GimbalRollDegree];
    PHOT.GIMBALyaw = [PHOT.GIMBALyaw; this_table.GimbalYawDegree];
    PHOT.OSDpitch = [PHOT.OSDpitch; this_table.FlightPitchDegree];
    PHOT.OSDroll = [PHOT.OSDroll; this_table.FlightRollDegree];
    PHOT.OSDyaw = [PHOT.OSDyaw; this_table.FlightYawDegree];
    PHOT.FlightXSpeed = [PHOT.FlightXSpeed; this_table.FlightXSpeed];
    PHOT.FlightYSpeed = [PHOT.FlightYSpeed; this_table.FlightYSpeed];
    PHOT.FlightZSpeed = [PHOT.FlightZSpeed; this_table.FlightZSpeed];
    PHOT.LightValue = [PHOT.LightValue; this_table.LightValue];

end


end