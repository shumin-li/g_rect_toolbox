%%% STABILIZE VIDEO
function[ motion, stable ] = g_videostabilize( frames, roi, L )

N = length( frames );
roiorig = roi;

%%% ESTIMATE PAIRWISE MOTION
Acum = [1 0 ; 0 1];
Tcum = [0 ; 0];
stable(1).roi = roiorig;
for k = 1 : N-1
    [A,T] = g_opticalflow( frames(k+1).im, frames(k).im, roi, L );
    motion(k).A = A;
    motion(k).T = T;
    [Acum,Tcum] = g_accumulatewarp( Acum, Tcum, A, T );
    roi = g_warp( roiorig, Acum, Tcum );
end

%%% STABILIZE TO LAST FRAME
stable(N).im = frames(N).im;
Acum = [1 0 ; 0 1];
Tcum = [0 ; 0];
for k = N-1 : -1 : 1
    [Acum,Tcum]  = g_accumulatewarp( Acum, Tcum, motion(k).A, motion(k).T );
    stable(k).im = g_warp( frames(k).im, Acum, Tcum );
end
