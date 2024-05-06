function varargout = g_rect_paramsGui(varargin)
% G_RECT_PARAMSGUI MATLAB code for g_rect_paramsGui.fig
%      G_RECT_PARAMSGUI, Open a GUI for easily add GCP points and creat the
%      parameters.dat file required by g_rect. It supports two folders of
%      images at the same time, one of raw images and one of stabilized
%      images (sometimes finding the boat is easier on the colored raw, but
%      you need the precision of the stabilized images.)
%      To open a folder, you need to choose an example image. Image
%      filenames must contain only one string of numbers of constant length.
%      Example: IMG_3456.jpg and IMG_0011.jpg 
%               or 342_img.png and 001_img.png
%
%      The GPS file in input must be one of the two:
%           Text file: 4 Columns : Lat; Lon; Date (yyyymmdd),; Time (HHMMSS)
%           Mat file: one variable named Coord with 3 columns: 
%               Lat; Lon; Time (datenum from the same reference year as the pictures, usually 0)
%
%      The choosed points may be shown on a map, defaults lat lon limits
%      are for Pointe-Aux-Crêpes. This needs the m_map toolbox.
%      Once all GCP are chosen, the next step button shows a dialog with all
%      the parameters needed for the parameters.dat file.
%
% See also: GUIDE, GUIDATA, GUIHANDLES
% Last Modified by GUIDE v2.5 04-Aug-2015 11:42:15

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @g_rect_paramsGui_OpeningFcn, ...
                   'gui_OutputFcn',  @g_rect_paramsGui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before g_rect_paramsGui is made visible.
function g_rect_paramsGui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to g_rect_paramsGui (see VARARGIN)

% Choose default command line output for g_rect_paramsGui
handles.output = hObject;
set(handles.tblPoints,'data',{})
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes g_rect_paramsGui wait for user response (see UIRESUME)
% uiwait(handles.mainWindow);


% --- Outputs from this function are returned to the command line.
function varargout = g_rect_paramsGui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function edRawFol_Callback(hObject, eventdata, handles)
% hObject    handle to edRawFol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edRawFol as text
%        str2double(get(hObject,'String')) returns contents of edRawFol as a double


% --- Executes during object creation, after setting all properties.
function edRawFol_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edRawFol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btnRawFolChng.
function btnRawFolChng_Callback(hObject, eventdata, handles)
% hObject    handle to btnRawFolChng (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[refFile, newFolder] = uigetfile({'*.jpg;*.tif;*.png;*.gif','All Image Files';'*.*','All Files' },'Select one of the Raw images');
set(handles.edRawFol,'String',newFolder)
[fmt, num, tot, maxi,mini] = extractFmtNum(refFile,newFolder);
set(handles.edRawFmt,'String',fmt)
if ~isfield(handles,'refFile')
    handles.refFile = num;
end
set(handles.edNumImage,'String',num2str(num));
set(handles.txOfImage,'String',sprintf('in %d image files',tot))

set(handles.sliImage,'Max',maxi)
set(handles.sliImage,'Value',num)
set(handles.sliImage,'Min',mini)
set(handles.sliImage, 'SliderStep', [1/tot , 10/tot ]);
handles.ImMode = 0;
set(handles.btnStbImage,'String','Show stabilized')
guidata(hObject,handles)
update_Imfig(handles,hObject);




function edRawFmt_Callback(hObject, eventdata, handles)
% hObject    handle to edRawFmt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edRawFmt as text
%        str2double(get(hObject,'String')) returns contents of edRawFmt as a double


% --- Executes during object creation, after setting all properties.
function edRawFmt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edRawFmt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edStbFol_Callback(hObject, eventdata, handles)
% hObject    handle to edStbFol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edStbFol as text
%        str2double(get(hObject,'String')) returns contents of edStbFol as a double


% --- Executes during object creation, after setting all properties.
function edStbFol_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edStbFol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btnStbFolChng.
function btnStbFolChng_Callback(hObject, eventdata, handles)
% hObject    handle to btnStbFolChng (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[refFile, newFolder] = uigetfile({'*.jpg;*.tif;*.png;*.gif','All Image Files';'*.*','All Files' },'Select one of the stabilized images');
set(handles.edStbFol,'String',newFolder)
[fmt, num, tot, maxi, mini] = extractFmtNum(refFile,newFolder);    
set(handles.edStbFmt,'String',fmt)
handles.refFile = num;
set(handles.edNumImage,'String',num2str(num));
set(handles.txOfImage,'String',sprintf('in %d image files',tot))

set(handles.sliImage,'Max',maxi)
set(handles.sliImage,'Value',num)
set(handles.sliImage,'Min',mini)
set(handles.sliImage, 'SliderStep', [1/tot , 10/tot ]);
handles.ImMode = 1;
set(handles.btnStbImage,'String','Show raw')
guidata(hObject,handles)
update_Imfig(handles,hObject);


function edStbFmt_Callback(hObject, eventdata, handles)
% hObject    handle to edStbFmt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edStbFmt as text
%        str2double(get(hObject,'String')) returns contents of edStbFmt as a double


% --- Executes during object creation, after setting all properties.
function edStbFmt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edStbFmt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edGPSfile_Callback(hObject, eventdata, handles)
% hObject    handle to edGPSfile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edGPSfile as text
%        str2double(get(hObject,'String')) returns contents of edGPSfile as a double


% --- Executes during object creation, after setting all properties.
function edGPSfile_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edGPSfile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btnLoadGPS.
function btnLoadGPS_Callback(hObject, eventdata, handles)
% hObject    handle to btnLoadGPS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[gpsfile, newFolder] = uigetfile({'*.txt;*.mat','Text of mat files';'*.*','All files'},'Select the boat GPS log file (text or mat)');
try
if strcmp(gpsfile(end-3:end),'mat')
    handles.Coord = load(fullfile(newFolder,gpsfile),'Coord');
else
    f = fopen(fullfile(newFolder,gpsfile),'r');
    data = textscan(f,'%n%n%s%s','delimiter',',','commentstyle','#');
    fclose(f);
    handles.Coord = [data{1} data{2} arrayfun(@(x,y) datenum([x{1} y{1}],'yyyymmddHHMMSS'),data{3},data{4})];
end
set(hObject,'String','GPS Loaded')
end
guidata(hObject,handles)

% --- Executes on slider movement.
function sliImage_Callback(hObject, eventdata, handles)
% hObject    handle to sliImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
num = round(get(hObject,'Value'));
set(handles.edNumImage,'String',num2str(num))
guidata(hObject,handles)
update_Imfig(handles,hObject)

% --- Executes during object creation, after setting all properties.
function sliImage_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function edNumImage_Callback(hObject, eventdata, handles)
% hObject    handle to edNumImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edNumImage as text
%        str2double(get(hObject,'String')) returns contents of edNumImage as a double
try
    set(handles.sliImage,'Value',str2double(get(hObject,'String')))
    
    guidata(hObject,handles)
    update_Imfig(handles,hObject)
end

% --- Executes during object creation, after setting all properties.
function edNumImage_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edNumImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btnStbImage.
function btnStbImage_Callback(hObject, eventdata, handles)
% hObject    handle to btnStbImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.ImMode
    set(hObject,'String','Show raw')
    handles.ImMode = 0;
else
    set(hObject,'String','Show stabilized')
    handles.ImMode = 1;
end
guidata(hObject,handles)
update_Imfig(handles,hObject);

% --- Executes on button press in btnAddBoat.
function btnAddBoat_Callback(hObject, eventdata, handles)
% hObject    handle to btnAddBoat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles,'imFig') && isfield(handles,'CurDateTime') && isfield(handles,'Coord')
    figure(handles.imFig)
    [x, y] = ginput(1);
    x = round(x); y = round(y);
    iGps = near(handles.CurDateTime,handles.Coord(:,3));
    Data = get(handles.tblPoints,'Data');
    Data(end+1,:) = {str2double(get(handles.edNumImage,'String')),...
        datestr(handles.CurDateTime,'yyyymmddTHHMMSS'),x,y,handles.Coord(iGps,1),handles.Coord(iGps,2)};
    set(handles.tblPoints,'data',Data)
    guidata(hObject,handles)
end
    
% --- Executes on button press in btnAdd.
function btnAdd_Callback(hObject, eventdata, handles)
% hObject    handle to btnAdd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles,'imFig')
    figure(handles.imFig)
    [x, y] = ginput(1);
    x = round(x); y = round(y);
    Data = get(handles.tblPoints,'Data');
    try
        das = datestr(handles.CurDateTime,'YYYYMMDDTHHMMSS');
    catch
        das = '';
    end
    Data(end+1,:) = {str2double(get(handles.edNumImage,'String')),das,x,y,0,0};
    set(handles.tblPoints,'data',Data)
    guidata(hObject,handles)
end


function edLatMax_Callback(hObject, eventdata, handles)
% hObject    handle to edLatMax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edLatMax as text
%        str2double(get(hObject,'String')) returns contents of edLatMax as a double


% --- Executes during object creation, after setting all properties.
function edLatMax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edLatMax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edLonMax_Callback(hObject, eventdata, handles)
% hObject    handle to edLonMax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edLonMax as text
%        str2double(get(hObject,'String')) returns contents of edLonMax as a double


% --- Executes during object creation, after setting all properties.
function edLonMax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edLonMax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edLonMin_Callback(hObject, eventdata, handles)
% hObject    handle to edLonMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edLonMin as text
%        str2double(get(hObject,'String')) returns contents of edLonMin as a double


% --- Executes during object creation, after setting all properties.
function edLonMin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edLonMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edLatMin_Callback(hObject, eventdata, handles)
% hObject    handle to edLatMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edLatMin as text
%        str2double(get(hObject,'String')) returns contents of edLatMin as a double


% --- Executes during object creation, after setting all properties.
function edLatMin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edLatMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btnMap.
function btnMap_Callback(hObject, eventdata, handles)
% hObject    handle to btnMap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    lat_min = str2double(get(handles.edLatMin,'String'));
    lat_max = str2double(get(handles.edLatMax,'String'));
    lon_min = str2double(get(handles.edLonMin,'String'));
    lon_max = str2double(get(handles.edLonMax,'String'));
catch
    return
end
handles.mapFig = figure;
m_proj('mercator','longitudes',[lon_min lon_max],'latitudes',[lat_min lat_max]);
hold on

switch get(get(handles.panGshhs,'SelectedObject'),'tag')
    case 'rbFull'
        m_gshhs_f('patch',[210 180 140]/255)
    case 'rbHigh'
        m_gshhs_h('patch',[210 180 140]/255)
end
m_grid('box','fancy','fontsize',12);
guidata(hObject,handles)
update_pts(handles,hObject)




function update_Imfig(handles,hObject)
if handles.ImMode
    ImFile = fullfile(get(handles.edStbFol,'String'),sprintf(get(handles.edStbFmt,'String'),str2double(get(handles.edNumImage,'String'))));
else
    ImFile = fullfile(get(handles.edRawFol,'String'),sprintf(get(handles.edRawFmt,'String'),str2double(get(handles.edNumImage,'String'))));
end
if exist(ImFile,'file')
    ImData = imread(ImFile);
    handles.CurDateTime = getDateTime(ImFile);
    if ~isfield(handles,'imFig')
        handles.imFig = figure;
        colormap(gray(256));
        handles.imIm = imagesc(ImData);
        handles.imTi = title(datestr(handles.CurDateTime,'dd mmm yyyy, HH:MM:SS'));
    else
        figure(handles.imFig)
        set(handles.imIm,'CData',ImData)
        set(handles.imTi,'String',datestr(handles.CurDateTime,'dd mmm yyyy, HH:MM:SS'))
    end
else
    set(handles.imIm,'CData',zeros(40,40))
    set(handles.imTi,'String',sprintf('There is no image named %s',ImFile))
end
guidata(hObject,handles)
update_pts(handles,hObject)

function datetime = getDateTime(ImFile)
info = imfinfo(ImFile);
if isfield(info,'DateTime')
    datetime = datenum(info.DateTime,'yyyy:mm:dd HH:MM:SS');
elseif isfield(info,'Comment')
    try
        datetime = datenum(info.Comment,'yyyy:mm:dd HH:MM:SS');
    catch
        datetime = 0;
    end
else
    datetime = 0;
end
        
        
function [filefmt, num,tot,maxi, mini] = extractFmtNum(filename, foldername)
indsNum = regexp(filename,'[0-9]');
if diff(indsNum) == 1;
    filefmt = [filename(1:indsNum(1)-1) '%0' num2str(length(indsNum)) '.0f' filename(indsNum(end)+1:end)];
    num = str2double(filename(indsNum));
    files = dir(foldername);
    tot = 0;
    maxi = 0;
    mini = Inf;
    for i=1:length(files)
        try
            if regexp(files(i).name,'[0-9]') == indsNum
                if strcmp(files(i).name(indsNum(end)+1:end),filename(indsNum(end)+1:end))
                    if strcmp(files(i).name(1:indsNum(1)-1),filename(1:indsNum(1)-1))
                    tot = tot+1;
                    maxi = max([maxi str2double(files(i).name(indsNum))]);
                    mini = min([mini str2double(files(i).name(indsNum))]);
                    end
                end
            end
        end
    end
else
    filefmt = filename;
    num = 1;
end

function update_pts(handles, hObject)
data = get(handles.tblPoints,'data');
if isfield(handles,'imFig')
    figure(handles.imFig)
    hold on
    if isfield(handles,'imPtsHandles') && isfield(handles,'imTxtHandles')
        try
            delete(handles.imPtsHandles)
            delete(handles.imTxtHandles)
        end
        handles.imPtsHandles = zeros(size(data,1),1);
        handles.imTxtHandles = zeros(size(data,1),1);
    end
    for i=1:size(data,1)
        handles.imPtsHandles(i) = plot(data{i,3},data{i,4},'ro');
        handles.imTxtHandles(i) = text(data{i,3},data{i,4},num2str(i));
    end
end
if isfield(handles,'mapFig')
    figure(handles.mapFig)
    hold on
    if isfield(handles,'mapPtsHandles') && isfield(handles,'mapTxtHandles')
        try
            delete(handles.mapPtsHandles)
            delete(handles.mapTxtHandles)
        end
        handles.mapPtsHandles = zeros(size(data,1),1);
        handles.mapTxtHandles = zeros(size(data,1),1);
    end
    for i=1:size(data,1)
        handles.mapPtsHandles(i) = m_plot(data{i,6},data{i,5},'ro');
        handles.mapTxtHandles(i) = m_text(data{i,6},data{i,5},num2str(i));
    end
end
guidata(hObject,handles)
        

% --- Executes on button press in btnRemove.
function btnRemove_Callback(hObject, eventdata, handles)
% hObject    handle to btnRemove (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles,'selected')
    data = get(handles.tblPoints,'data');
    reminds = handles.selected(:,1);
    inds = setxor(1:size(data,1),reminds);
    data = data(inds,:);
    set(handles.tblPoints,'data',data)
end
guidata(hObject,handles)
update_pts(handles,hObject)

function [ind valOut] = near(valIn, vecIn)
    [~,ind] = min(abs(vecIn-valIn));
    valOut = vecIn(ind);


% --- Executes when selected cell(s) is changed in tblPoints.
function tblPoints_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to tblPoints (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
handles.selected = eventdata.Indices;
guidata(hObject,handles)


% --- Executes on button press in btnFinish.
function btnFinish_Callback(hObject, eventdata, handles)
% hObject    handle to btnFinish (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.mainWindow,'visible','off')
if handles.ImMode
    files = {get(handles.edStbFol,'String'),get(handles.edStbFmt,'String')};
else
    files = {get(handles.edRawFol,'String'),get(handles.edRawFmt,'String')};
end
handles.f = figure('Visible','off','Position',[360,500,400,436],'Name','Last metadata!');

uicontrol('Style','text','String','imgFname: ','Position',[5 400 85 22],'HorizontalAlignment','right');
handles.imgFname    = uicontrol('Style','edit','String',sprintf(['%s' files{2}],files{1},handles.refFile),'Position',[95 400 300 22],'HorizontalAlignment','right');

uicontrol('Style','text','String','firstimgFname: ','Position',[5 372 85 22],'HorizontalAlignment','right');
handles.firstimgFname    = uicontrol('Style','edit','String',sprintf(['%s' files{2}],files{1},get(handles.sliImage,'Min')),'Position',[95 372 300 22],'HorizontalAlignment','right');

uicontrol('Style','text','String','lastimgFname: ','Position',[5 344 85 22],'HorizontalAlignment','right');
handles.lastimgFname     = uicontrol('Style','edit','String',sprintf(['%s' files{2}],files{1},get(handles.sliImage,'Max')),'Position',[95 344 300 22],'HorizontalAlignment','right');

uicontrol('Style','text','String','outputFname: ','Position',[5 316 85 22],'HorizontalAlignment','right');
handles.outputFname    = uicontrol('Style','edit','String','IMG_rect.mat','Position',[95 316 300 22],'HorizontalAlignment','right');

handles.field = uicontrol('Style','checkbox','String','field','Position',[175 288 150 22],'Value',1);

uicontrol('Style','text','String','Camera position:','Position',[5 288 145 22],'HorizontalAlignment','left');

uicontrol('Style','text','String','Lon: ','Position',[20 260 50 22],'HorizontalAlignment','right');
handles.LON0   = uicontrol('Style','edit','String','','Position',[75 260 100 22],'HorizontalAlignment','right');
uicontrol('Style','text','String','Lat: ','Position',[175 260 50 22],'HorizontalAlignment','right');
handles.LAT0   = uicontrol('Style','edit','String','','Position',[230 260 100 22],'HorizontalAlignment','right');

uicontrol('Style','text','String','Offset ic: ','Position',[20 232 50 22],'HorizontalAlignment','right');
handles.ic   = uicontrol('Style','edit','String','0','Position',[75 232 100 22],'HorizontalAlignment','right');
uicontrol('Style','text','String','Offset jc: ','Position',[175 232 50 22],'HorizontalAlignment','right');
handles.jc   = uicontrol('Style','edit','String','0','Position',[230 232 100 22],'HorizontalAlignment','right');

uicontrol('Style','text','String','hfov: ','Position',[20 204 50 22],'HorizontalAlignment','right');
handles.hfov   = uicontrol('Style','edit','String','40','Position',[75 204 100 22],'HorizontalAlignment','right');
uicontrol('Style','text','String','dhfov: ','Position',[175 204 50 22],'HorizontalAlignment','right');
handles.dhfov   = uicontrol('Style','edit','String','10','Position',[230 204 100 22],'HorizontalAlignment','right');

uicontrol('Style','text','String','lambda: ','Position',[20 176 50 22],'HorizontalAlignment','right');
handles.lambda   = uicontrol('Style','edit','String','5','Position',[75 176 100 22],'HorizontalAlignment','right');
uicontrol('Style','text','String','dlambda: ','Position',[175 176 50 22],'HorizontalAlignment','right');
handles.dlambda   = uicontrol('Style','edit','String','5','Position',[230 176 100 22],'HorizontalAlignment','right');

uicontrol('Style','text','String','phi: ','Position',[20 148 50 22],'HorizontalAlignment','right');
handles.phi  = uicontrol('Style','edit','String','0','Position',[75 148 100 22],'HorizontalAlignment','right');
uicontrol('Style','text','String','dphi: ','Position',[175 148 50 22],'HorizontalAlignment','right');
handles.dphi   = uicontrol('Style','edit','String','5','Position',[230 148 100 22],'HorizontalAlignment','right');

uicontrol('Style','text','String','H: ','Position',[20 120 50 22],'HorizontalAlignment','right');
handles.H   = uicontrol('Style','edit','String','155','Position',[75 120 100 22],'HorizontalAlignment','right');
uicontrol('Style','text','String','dH: ','Position',[175 120 50 22],'HorizontalAlignment','right');
handles.dH   = uicontrol('Style','edit','String','20','Position',[230 120 100 22],'HorizontalAlignment','right');

uicontrol('Style','text','String','theta: ','Position',[20 92 50 22],'HorizontalAlignment','right');
handles.theta   = uicontrol('Style','edit','String','265','Position',[75 92 100 22],'HorizontalAlignment','right');
uicontrol('Style','text','String','dtheta: ','Position',[175 92 50 22],'HorizontalAlignment','right');
handles.dtheta   = uicontrol('Style','edit','String','20','Position',[230 92 100 22],'HorizontalAlignment','right');

uicontrol('Style','text','String','polyOrder: ','Position',[20 64 50 22],'HorizontalAlignment','right');
handles.polyOrder   = uicontrol('Style','edit','String','0','Position',[75 64 100 22],'HorizontalAlignment','right');
uicontrol('Style','text','String','precision: ','Position',[175 64 50 22],'HorizontalAlignment','right');
handles.precision  = uicontrol('Style','edit','String','double','Position',[230 64 100 22],'HorizontalAlignment','right');

handles.btn = uicontrol('Style','pushbutton','String','Generate the paramters file','Position',[20 2 360 60],'Callback',{@finalstep,hObject});

set(handles.f,'visible','on')
guidata(hObject,handles)

function finalstep(hObject, eventdata, otherObject)
handles = guidata(otherObject);
set(handles.f,'visible','off')
[filename, pathname] = uiputfile({'*.dat;*.txt','All Text Files';'*.*','All Files' },'Find a place where to save the parameter file','parameters.dat');
f = fopen(fullfile(pathname,filename),'w');
fprintf(f,'%% I/O information\n');
fprintf(f,'imgFname  =  ''%s'';\n',get(handles.imgFname,'String'));
fprintf(f,'firstImgFname  =  ''%s'';\n',get(handles.firstimgFname,'String'));
fprintf(f,'lastImgFname  =  ''%s'';\n',get(handles.lastimgFname,'String'));
fprintf(f,'outputFname  =  ''%s'';\n',get(handles.outputFname,'String'));
fprintf(f,'\n%% Field or lab case situation. \n%% Set field = true for field situation and field = false for lab situation.\n');
if get(handles.field,'value')
    fprintf(f,'field = true;\n');
else
    fprintf(f,'field = false;\n');
end
fprintf(f,'\n%%Camera position\n%% lat/lon for field situation\n%% meter for lab situation\n');
fprintf(f,'LON0 = %s;\n',get(handles.LON0,'String'));
fprintf(f,'LAT0 = %s;\n',get(handles.LAT0,'String'));

fprintf(f,'\n%% Offset from center of the principal point (generally zero)\n');
fprintf(f,'ic = %s;\njc = %s;\n',get(handles.ic,'String'),get(handles.jc,'String'));
fprintf(f,'\n%%Parameters\n');
fprintf(f,'hfov = %s;     %% Field of view of the camera\n',get(handles.hfov,'String'));
fprintf(f,'lambda = %s;   %% Dip angle below horizontal (e.g. straight down = 90, horizontal = 0)  \n',get(handles.lambda,'String'));
fprintf(f,'phi = %s;      %% Tilt angle (generally close to 0).\n',get(handles.phi,'String'));
fprintf(f,'H = %s;    %% Camera altitude (m)\n',get(handles.H,'String'));
fprintf(f,'theta = %s;     %% View angle anticlockwise from North (e.g. straight East = 270)\n',get(handles.theta,'String'));

fprintf(f,'\n%% Uncertainty in parameters. Set the uncertainty to 0.0 for fixed parameters.\n');
fprintf(f,'dhfov = %s; \n',get(handles.dhfov,'String'));
fprintf(f,'dlambda = %s; \n',get(handles.dlambda,'String'));
fprintf(f,'dphi = %s;   \n',get(handles.dphi,'String'));
fprintf(f,'dH = %s; \n',get(handles.dH,'String'));
fprintf(f,'dtheta = %s;  \n',get(handles.dtheta,'String'));

fprintf(f,'\n%% Order of the polynomial correction (0, 1 or 2)\n');
fprintf(f,'polyOrder = %s',get(handles.polyOrder,'String'));
fprintf(f,'\n%% To save memory calculation can be done in single precision.\n%% For higher precision set the variable ''precision'' to ''double''\n');
fprintf(f,'precision = ''%s'';\n',get(handles.precision,'String'));
fprintf(f,'\n%% Ground Control Points (GCP).\ngcpData = true;\n');

data = get(handles.tblPoints,'data');
for i = 1:size(data,1)
    fprintf(f,'%.0f  %.0f  %.8f  %.8f\n',data{i,3},data{i,4},data{i,6},data{i,5});
end
fclose(f);

close all
