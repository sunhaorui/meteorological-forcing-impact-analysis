function [SWE_PRIOR,SD_PRIOR,mask,lat,lon]=load_basin_wide_prior_SWE_and_SD(coords,WY,rean_dir,aso_dir)
WY_str = sprintf('%d_%02d', ...
    WY - 1, ...
    mod(WY, 100));
for itile=1:size(coords,1)
    COORDS=coords(itile,:);
    [appendlon,appendlat,append_val_lat,append_val_lon]=coord_process(COORDS);
    coord_var=[appendlat num2str(floor(abs(COORDS(1)))) append_val_lat appendlon num2str(floor(abs(COORDS(2)))) append_val_lon];
    % load reanaylysis SWE
    fn=[rean_dir coord_var '_agg_5_final/WY' num2str(WY) '/SWE_SCA_PRIOR/' ...
    coord_var '_agg_5_SWE_SCA_PRIOR_WY' WY_str '.nc'];
    SWE_PRIOR=squeeze(ncread(fn,'SWE_Prior',[1 1 1 1],[Inf Inf 1 Inf]));
    % load reanalysis SD
    fn=[rean_dir coord_var '_agg_5_final/WY' num2str(WY) '/SD_PRIOR/' ...
    coord_var '_agg_5_SD_PRIOR_WY' WY_str '.nc'];
    SD_PRIOR=squeeze(ncread(fn,'SD_Prior',[1 1 1 1],[Inf Inf 1 Inf]));
end

load([aso_dir 'USCAMB_mask.mat']);
mask = USCAMB_mask.mask;
lat = USCAMB_mask.lat;
lon = USCAMB_mask.lon;

for iday=1:size(SWE_PRIOR,3)
    SWE_PRIOR(:,:,iday)=squeeze(SWE_PRIOR(:,:,iday)).*mask;
    SD_PRIOR(:,:,iday)=squeeze(SD_PRIOR(:,:,iday)).*mask;
end
end