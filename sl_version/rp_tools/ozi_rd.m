function gps=ozi_rd(fname);
% OZI_RD Reads Trackplot files from OZI Explorer
%
%

% June/2016  rich@eos.ubc.ca


fd=fopen(fname);
if fd<0,
 error(['Error opening file: ' fname]);
end;


% Skip header 
for k=1:7,
 l=fgetl(fd);
end;

k=0;
while length(l)>1,
  vals=sscanf(l,'%f,%f,%d,%f,%f');
  k=k+1;
  gps.lat(k)=vals(1);
  gps.lon(k)=vals(2);
  gps.alt(k)=vals(3);
  gps.yd(k)=vals(4);
  gps.mtime(k)=datenum(l(49:end),'mm/dd/yyyy, HH:MM:SS PM')-7/24;  % PDT
  l=fgetl(fd);
end;
fclose(fd);
