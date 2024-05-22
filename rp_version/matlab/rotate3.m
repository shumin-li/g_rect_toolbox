function [nyaw,npitch,nroll]=rotate3(yaw,pitch,roll,left,up,cw,alpha)
% ROTATE3 Calculates new yaw/pitch/roll after a small change
%         in viewpoint (more yaw/pitch/roll) using quaternions.
%
%         This is expecially useful for situations where pitch is
%         at or close to 90 degrees as it avoids 'gimbal lock'
%         situations.

% R. Pawlowicz 14/Mar/2023

if numel(yaw)==1
    [n,m]=size(left);
else
    [n,m]=size(yaw);
end


% Quaternion for the current orientation from its Euler angles
% Assumptions in this math are:
%    Rotate about Z axis (yaw), then Y (pitch), and then X (roll)
%    Quaternion parts are: [w x y z]

c1=cosd( -roll(:)/2);
c2=cosd(-pitch(:)/2);
c3=cosd(   yaw(:)/2);
s1=sind( -roll(:)/2);
s2=sind(-pitch(:)/2);
s3=sind(   yaw(:)/2);

rs.w = [ c1.*c2.*c3+s1.*s2.*s3];
rs.x = [-c1.*s2.*c3-s1.*c2.*s3];
rs.y = [ s1.*s2.*c3-c1.*c2.*s3];
rs.z = [ c1.*s2.*s3-s1.*c2.*c3];

 
 
% Quaternion  for the extra rotation. If we are looking
% sideways, it is useful for this to be done FIRST. Then
% the heading change makes the coastlines move left/right
% on the picture.
% However, if we are looking downwards, changing the heading
% rotates the picture. It is better to do this LAST. Then heading
% change ALSO moves the coastlines left/right on the picture.
%
% alpha is the weighting for the degree to which the angle
% changes are done first, and the default is to weight things
% by the cosine of the pitch angle. 

 
if nargin<6
 alpha=cosd(pitch(:)).^2;
end

c1=cosd( -cw(:)/2.*alpha);
c2=cosd( -up(:)/2.*alpha);
c3=cosd(left(:)/2.*alpha);
s1=sind( -cw(:)/2.*alpha);
s2=sind( -up(:)/2.*alpha);
s3=sind(left(:)/2.*alpha);

% First rotation
drs.w = [ c1.*c2.*c3+s1.*s2.*s3];
drs.x = [-c1.*s2.*c3-s1.*c2.*s3];
drs.y = [ s1.*s2.*c3-c1.*c2.*s3];
drs.z = [ c1.*s2.*s3-s1.*c2.*c3];

c1=cosd( -cw(:)/2.*(1-alpha));
c2=cosd( -up(:)/2.*(1-alpha));
c3=cosd(left(:)/2.*(1-alpha));
s1=sind( -cw(:)/2.*(1-alpha));
s2=sind( -up(:)/2.*(1-alpha));
s3=sind(left(:)/2.*(1-alpha));

% last rotation
drs2.w = [ c1.*c2.*c3+s1.*s2.*s3];
drs2.x = [-c1.*s2.*c3-s1.*c2.*s3];
drs2.y = [ s1.*s2.*c3-c1.*c2.*s3];
drs2.z = [ c1.*s2.*s3-s1.*c2.*c3];
 


% Rotate first - good for horizontal-ish viewpoints
q.w = [rs.w.*drs.w - rs.x.*drs.x - rs.y.*drs.y - rs.z.*drs.z];
q.x = [rs.w.*drs.x + rs.x.*drs.w + rs.y.*drs.z - rs.z.*drs.y];         
q.y = [rs.w.*drs.y - rs.x.*drs.z + rs.y.*drs.w + rs.z.*drs.x];
q.z = [rs.w.*drs.z + rs.x.*drs.y - rs.y.*drs.x + rs.z.*drs.w];
 
% Rotate last - good for vertical-ish viewpoints
q.w = [drs2.w.*q.w - drs2.x.*q.x - drs2.y.*q.y - drs2.z.*q.z];
q.x = [drs2.w.*q.x + drs2.x.*q.w + drs2.y.*q.z - drs2.z.*q.y];         
q.y = [drs2.w.*q.y - drs2.x.*q.z + drs2.y.*q.w + drs2.z.*q.x];
q.z = [drs2.w.*q.z + drs2.x.*q.y - drs2.y.*q.x + drs2.z.*q.w];
  

   
% ...and take qz back to Euler angles
% [w x y z]
 
[nroll,npitch,nyaw]=deal(NaN(n,m));

%s =     2*(qz(:,3).*qz(:,4) + qz(:,1).*qz(:,2));
%c =   qz(:,1).*qz(:,1) - qz(:,2).*qz(:,2) - qz(:,3).*qz(:,3) + qz(:,4).*qz(:,4);
%nroll(:) = atan2d(s, c);
s =     2*(q.x.*q.y - q.z.*q.w);
c =   1-2*(q.x.*q.x + q.z.*q.z);
% Leading negative because of historical sign change
nroll(:) = -atan2d(s, c);

% Note this means pitch is between -90 and 90.
%npitch(:) = asind(min(1,max(-1,-2*(qz(:,2).*qz(:,4) - qz(:,1).*qz(:,3)) )));

% Leading negative because of historical sign change
npitch(:) = -asind(min(1,max(-1,-2*(q.y.*q.z + q.x.*q.w) )));
 
%s =     2*(qz(:,2).*qz(:,3) + qz(:,1).*qz(:,4));
%c =  qz(:,1).*qz(:,1) + qz(:,2).*qz(:,2)- qz(:,3).*qz(:,3) - qz(:,4).*qz(:,4);
%nyaw(:) = atan2d(s, c);
s =     2*(q.x.*q.z - q.y.*q.w);
c =  1 - 2*(q.x.*q.x + q.y.*q.y);
nyaw(:) = atan2d(s, c);


% Gimbal lock condition - choose a different solution here.
ii=abs(npitch(:)-90)<1e-5;
if any(ii)
    npitch(ii)=90;
    nroll(ii)=0;
 %   nyaw(ii)=-2*atan2d(qz(ii,2),qz(ii,1));
    nyaw(ii)= 2*atan2d(-q.y,q.w);
end
 
ii=abs(npitch(:)+90)<1e-5;
if any(ii)
    npitch(ii)=-90;
    nroll(ii)=0;
  %  nyaw(ii)= 2*atan2d(qz(ii,2),qz(ii,1));
    nyaw(ii)= 2*atan2d(-q.y,q.w);
end

% If pitch goes beyond 90 degrees, the asin() returns less than 90, but roll flips 
% 180 and heading changes by 180 degrees. But we would prefer that this didn't 
% happen to the angles, so undo those changes so that roll is always around 0.

ii=abs(nroll)>90;                         % If roll shows upside down...
if any(ii)
    nroll(ii)=mod(nroll(ii),360)-180;     % Roll flips back 180, 
    npitch(ii)=180-npitch(ii);            % Pitch is more than 90 instead of less
    nyaw(ii)=rem(nyaw(ii)-yaw(ii)+360,360)+yaw(ii)-180;  % Change by 180, try to stay close to original.
end

 