function err = g_error_polyfit(cv,lonlon,latlat,err_ll,order);

n_gcp = length(err_ll);
err   = 0;

for k = 1:n_gcp

  if order == 1
      
    efit = cv(1)*lonlon(k)+cv(2)*latlat(k)+cv(3);  
    
  elseif order == 2
      
    efit = cv(1)*lonlon(k)^2+cv(2)*latlat(k)^2+cv(3)*lonlon(k)*latlat(k)+cv(4)*lonlon(k)+cv(5)*latlat(k)+cv(6);
    
  end
  
  err = err + (efit-err_ll(k))^2;

end