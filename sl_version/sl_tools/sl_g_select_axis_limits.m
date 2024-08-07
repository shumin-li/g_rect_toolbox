%% sl_g_select_axis_limits
function axisLimits = sl_g_select_axis_limits(opts,varargin)


% default values of the parameters
cutRes = 3; % m
alphadata = 0.5; % transparency


k=1;
while k<=length(varargin)
    switch lower(varargin{k}(1:3))
        case 'cut' % cutoff resolution (m) for image pixels
            cutRes =varargin{k+1};
        case 'lis'
            imgFnameList = varargin{k+1};
        case 'alp'
            alphadata = varargin{k+1};
    end
    k = k+2;
end

%%

imgDir = opts.imgDir;


% create a list of image filenames to be previewed
if ~isempty(opts.imgFnameList)
    imgFnameList = opts.imgFanmeList;
elseif ~isempty(opts.firstImgNum) && ~isempty(opts.lastImgNum)
    imgNumberList = [opts.firstImgNum, opts.lastImgNum];
    for ii = 1:numel(imgNumberList)
        imgFnameList{ii} = ['DJI_',sprintf('%04d',imgNumberList(ii)),'.JPG'];
    end

end


%% load database
load(opts.databasePath); % A data struct named 'DB'


ok = 'n';

while ok ~= 'y'
    for mm = 1:numel(imgFnameList)

        imgFname = imgFnameList{mm};
        corrFind = find(contains({DB.imgFname}, imgFname) & contains({DB.folder}, imgDir));

        imgInfo   = imfinfo([imgDir imgFname]);
        imgWidth  = imgInfo.Width;
        imgHeight = imgInfo.Height;

        nn = 5;
        xp = repmat([1:nn:imgWidth],ceil(imgHeight/nn),1);
        yp = repmat([1:nn:imgHeight]',1,ceil(imgWidth/nn));


        % Transform camera coordinate to ground coordinate. (for a fraction of the image)
        [LON, LAT] = g_pix2ll(xp,yp,imgWidth,imgHeight,...
            DB(corrFind).lambda,DB(corrFind).phi,DB(corrFind).theta,...
            DB(corrFind).H,DB(corrFind).LON0,DB(corrFind).LAT0,...
            opts.frameRef, DB(corrFind).lens);

        Delta = g_res(LON, LAT, opts.frameRef)/nn;


        lon_min(mm) = min(LON(Delta<cutRes));
        lon_max(mm) = max(LON(Delta<cutRes));
        lat_min(mm) = min(LAT(Delta<cutRes));
        lat_max(mm) = max(LAT(Delta<cutRes));

    end
    axisLimitsAttempt = [min(lon_min), max(lon_max), min(lat_min), max(lat_max)];

    sl_helper_load_references;


    %%

    figure(3)
    clf
    set(gcf,'color','w','position',[0 0 800 800]); % TODO: change it later for compatability

    m_proj('lambert','long',[axisLimitsAttempt(1) axisLimitsAttempt(2)],...
        'lat',[axisLimitsAttempt(3) axisLimitsAttempt(4)]);

    for mm = 1:numel(imgFnameList)

        imgFname = imgFnameList{mm};
        corrFind = find(contains({DB.imgFname}, imgFname) & contains({DB.folder}, imgDir));
        rgb0=imread([imgDir imgFname]);
        sl_mapping_show(DB, corrFind, rgb0, axisLimitsAttempt, 'res',1,'show','yes','alp',0.5);
        title(imgFname + ", " + datestr(DB(corrFind).mtimePhoto))
        sl_helper_draw_references;

    end

    previewInput = input("Ready to proceed?  ['y' or 'n'] \n",'s');

    if previewInput == 'y'
        ok = 'y';
    else
        cutRes = input("give a new cutoff resolution (m) \n [currently " + cutRes + " m]\n");
    end


end


%% draw axisLimits

disp('drawing a contour to indicated the area of interest:')
axisLimitsSelect = m_ginput;
axisLimits = [min(axisLimitsSelect(:,1)), max(axisLimitsSelect(:,1)), ...
    min(axisLimitsSelect(:,2)), max(axisLimitsSelect(:,2))];
m_line(axisLimits([1 2 2 1 1]), axisLimits([3 3 4 4 3]),'color','k','linesty','--','linewidth',2);
m_line(axisLimitsSelect(:,1), axisLimitsSelect(:,2),'color','r');


end