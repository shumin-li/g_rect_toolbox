function[ f2 ] = g_warp( f, A, T )

Method = 'cubic';

[ydim,xdim]   = size( f );
[xramp,yramp] = meshgrid( [1:xdim]-xdim/2, [1:ydim]-ydim/2 );

P = [xramp(:)' ; yramp(:)'];
P = A * P;

xramp2 = reshape( P(1,:), ydim, xdim ) + T(1);
yramp2 = reshape( P(2,:), ydim, xdim ) + T(2);
%f2 = interp2( xramp, yramp, f, xramp2, yramp2, 'bicubic' ); % warp
f2 = interp2( xramp, yramp, f, xramp2, yramp2, Method ); % warp
ind = find( isnan(f2) );
f2(ind) = 0;