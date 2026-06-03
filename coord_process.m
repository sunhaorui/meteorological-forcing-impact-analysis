function [appendlon, appendlat, append_val_lat, append_val_lon] = coord_process(coords)

if coords(1)<0;
    appendlat = 'S';
else
    appendlat = 'N';
end;

if coords(2)<0;
    appendlon = 'W';
else
    appendlon = 'E';
end;

if coords(1) - floor(coords(1)) == 0.5; 
    append_val_lat = '_5';
else
    append_val_lat = '_0';
end;

if coords(2) - floor(coords(2)) == 0.5; 
    append_val_lon = '_5';
else
    append_val_lon = '_0';
end;

end