function [SWE_POST,SD_POST]=load_basin_wide_post_SWE_and_SD(coords,WY,rean_dir,aso_dir)
WY_str = sprintf('%d_%02d', ...
    WY - 1, ...
    mod(WY, 100));
for itile=1:size(coords,1)
    COORDS=coords(itile,:);
    [appendlon,appendlat,append_val_lat,append_val_lon]=coord_process(COORDS);
    coord_var=[appendlat num2str(floor(abs(COORDS(1)))) append_val_lat appendlon num2str(floor(abs(COORDS(2)))) append_val_lon];
    % load reanaylysis SWE
    fn=[rean_dir coord_var '_agg_5_final/WY' num2str(WY) '/SWE_SCA_POST/' ...
    coord_var '_agg_5_SWE_SCA_POST_WY' WY_str '.nc'];
    SWE_POST=squeeze(ncread(fn,'SWE_Post',[1 1 1 1],[Inf Inf 1 Inf]));
    % load reanalysis SD
    fn=[rean_dir coord_var '_agg_5_final/WY' num2str(WY) '/SD_POST/' ...
    coord_var '_agg_5_SD_POST_WY' WY_str '.nc'];
    SD_POST=squeeze(ncread(fn,'SD_Post',[1 1 1 1],[Inf Inf 1 Inf]));
end

load([aso_dir 'USCAMB_mask.mat']);
mask = USCAMB_mask.mask;
lat = USCAMB_mask.lat;
lon = USCAMB_mask.lon;

for iday=1:size(SWE_POST,3)
    SWE_POST(:,:,iday)=squeeze(SWE_POST(:,:,iday)).*mask;
    SD_POST(:,:,iday)=squeeze(SD_POST(:,:,iday)).*mask;
end
end