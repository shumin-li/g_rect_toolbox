function[ Acum, Tcum ] = g_opticalflow( f1, f2, roi, L )

f2orig = f2;
Acum = [1 0 ; 0 1];
Tcum = [0 ; 0];

for k = L : -1 : 0
    
    %%% DOWN-SAMPLE
    f1d = g_down( f1, k );
    f2d = g_down( f2, k );
    ROI = g_down( roi, k );
    
    %%% COMPUTE MOTION
    [Fx,Fy,Ft] = g_spacetimederiv( f1d, f2d );
    [A,T]      = g_computemotion( Fx, Fy, Ft, ROI );
    T = (2^k) * T;
    [Acum,Tcum] = g_accumulatewarp( Acum, Tcum, A, T );
    
    %%% WARP ACCORDING TO ESTIMATED MOTION
    f2 = g_warp( f2orig, Acum, Tcum );
    
end