function generate_basin_time_series(ERA5,MERRA2,NLDAS2,ASO_data,ASO_SWE_adjusted)
% compute basin-averaged data
ERA5_SWE_ave = squeeze(nanmean(ERA5.SWE,[1 2]));
MERRA2_SWE_ave = squeeze(nanmean(MERRA2.SWE,[1 2]));
NLDAS2_SWE_ave = squeeze(nanmean(NLDAS2.SWE,[1 2]));
ASO_SWE_ave = squeeze(nanmean(ASO_SWE_adjusted,[1 2]));

ERA5_SD_ave = squeeze(nanmean(ERA5.SD,[1 2]));
MERRA2_SD_ave = squeeze(nanmean(MERRA2.SD,[1 2]));
NLDAS2_SD_ave = squeeze(nanmean(NLDAS2.SD,[1 2]));
ASO_SD_ave = squeeze(nanmean(ASO_data.SD_ASO_WY2018_19,[1 2]));
ASO_dowy = ASO_data.ASO_DOWY_WY2018_19;

% plot figure
figure;
t = tiledlayout(2,1,'TileSpacing','Compact','Padding','Compact');
nexttile; hold all;
h1=plot(1:365,ERA5_SWE_ave,'Color',[0 0.4470 0.7410],'LineWidth',2);
h2=plot(1:365,MERRA2_SWE_ave,'Color',[0.85 0.325 0.098],'LineWidth',2);
h3=plot(1:365,NLDAS2_SWE_ave,'Color',[0.4940 0.1840 0.5560],'LineWidth',2);
h4=plot(ASO_dowy,ASO_SWE_ave,'kd','MarkerFaceColor','k','MarkerSize',9);
ylabel('SWE (m)'); 
xlim([1 365]);xticks([1 183 335]);xticklabels({'Oct','Apr','Sep'})
plot(ASO_dowy(1),ASO_SWE_ave(1),'rd','MarkerFaceColor','r','MarkerSize',9);

nexttile; hold all;
h1=plot(1:365,ERA5_SD_ave,'Color',[0 0.4470 0.7410],'LineWidth',2);
h2=plot(1:365,MERRA2_SD_ave,'Color',[0.85 0.325 0.098],'LineWidth',2);
h3=plot(1:365,NLDAS2_SD_ave,'Color',[0.4940 0.1840 0.5560],'LineWidth',2);
h4=plot(ASO_dowy,ASO_SD_ave,'kd','MarkerFaceColor','k','MarkerSize',9);
ylabel('SD (m)'); 
xlim([1 365]);xticks([1 183 335]);xticklabels({'Oct','Apr','Sep'})
plot(ASO_dowy(1),ASO_SD_ave(1),'rd','MarkerFaceColor','r','MarkerSize',9);

end