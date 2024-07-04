%% sl_helper_load_references


% load data for ground references.

% If a coastline file was given - we expect the
% coast points to be in an nx2 vector 'ncst' of [long lat].

if opts.isgcp, disp('TODO: deal with ground control points'); end

if opts.isCoastline,load(opts.coastlinePath); end % ncst

if opts.isDrifter
    if contains(opts.drifterPath,'.mat')
        load(opts.drifterPath)
    else
        drifterFind = dir([dateDir,'drifter/*.mat']);
        load([drifterFind.folder,'/',drifterFind.name]); % a struct named 'drift'
    end
end

if opts.isShipGPS
    if contains(opts.shipPath,'.mat')
        load(opts.shipPath);
    else
        shipFind = dir([dateDir,'OziExplorer/*.plt']);
        ship_gps = ozi_rd([shipFind.folder,'/',shipFind.name]); % ship_gps
    end
end

