% Test code for Merced basin
clear all;close all;clc
%% INPUTS
% Forcing simulations: ERA5, MERRA2, NLDAS2 are single-forcing
file_prefix={'ERA5','MERRA2','NLDAS2'};
% Water Year
WY = 2019; 
% Reanalysis tile location (lower-left corner) for Merced
coords=[37 -120]; % 37 N, 120 W
% Reanalysis output file directory
root_dir='~/OUTPUT/USCAMB/';
% ASO directory (resampled to model grids already)
aso_dir = '~/MF_code_and_data/ASO/';

%% Extract Prior estimates
% Load ASO raw data (resampled to model resolution)
ASO_data = create_ASO_data_structure(aso_dir,WY);
% Load prior daily SWE and SD maps simulated with single forcing products
for ifile = 1:length(file_prefix)
    rean_dir = [root_dir file_prefix{ifile} '_'];
    [SWE_PRIOR,SD_PRIOR,mask,lat,lon]=load_basin_wide_prior_SWE_and_SD(coords,WY,rean_dir,aso_dir);
    eval([file_prefix{ifile} '.SWE = SWE_PRIOR;'])
    eval([file_prefix{ifile} '.SD  = SD_PRIOR;'])
end
% Compute adjusted ASO SWE = ASO SD x mean prior snow density
[ASO_SWE_adjusted] = adjust_ASO_SWE_using_model_density(ERA5,MERRA2,NLDAS2,ASO_data,mask);

%% Generate figures for prior estimates
% Basin-average time series
generate_basin_time_series(ERA5,MERRA2,NLDAS2,ASO_data,ASO_SWE_adjusted);

% Spatial maps of SWE error
generate_spatial_SWE_error_maps(ERA5,MERRA2,NLDAS2,ASO_data,ASO_SWE_adjusted,mask,lat,lon,WY);

% Stacked bars of spatial SWE error components
STATS = generate_spatial_SWE_comparison_bars(ERA5,MERRA2,NLDAS2,ASO_data, ...
    ASO_SWE_adjusted,mask,WY);

% MF benefit
% Load multi-forcing SWE and SD maps
rean_dir = [root_dir 'mixed_RMSE_weight_'];
[MF_SWE, MF_SD, mask] = load_basin_wide_prior_SWE_and_SD(coords, WY,rean_dir,aso_dir);
MF.SWE = MF_SWE;
MF.SD = MF_SD;
% Bar plots showing the benefit of MF
STATS = generate_MF_stats_figure(ERA5,MERRA2,NLDAS2,MF,ASO_data,ASO_SWE_adjusted, ...
    mask, WY, 'Merced');

%% Extract Posterior estimates
% Load posterior daily SWE and SD maps simulated with single forcing products
for ifile = 1:length(file_prefix)
    rean_dir = [root_dir file_prefix{ifile} '_'];
    [SWE_POST,SD_POST]=load_basin_wide_post_SWE_and_SD(coords,WY,rean_dir,aso_dir);
    eval([file_prefix{ifile} '.SWE = SWE_POST;'])
    eval([file_prefix{ifile} '.SD  = SD_POST;'])
end
% Compute adjusted ASO SWE = ASO SD x mean prior snow density
[ASO_SWE_adjusted] = adjust_ASO_SWE_using_model_density(ERA5,MERRA2,NLDAS2,ASO_data,mask);

%% generate figure for posterior accuracy
% MF benefit
% Load multi-forcing SWE and SD maps
rean_dir = [root_dir 'mixed_RMSE_weight_'];
[MF_SWE, MF_SD] = load_basin_wide_post_SWE_and_SD(coords, WY,rean_dir,aso_dir);
MF.SWE = MF_SWE;
MF.SD = MF_SD;
% Bar plots showing the benefit of MF
STATS = generate_MF_stats_figure(ERA5,MERRA2,NLDAS2,MF,ASO_data,ASO_SWE_adjusted, ...
    mask, WY, 'Merced');

%% posterior uncertainty characterization
% Load posterior daily SWE mean and standard deviation
for ifile = 1:length(file_prefix)
    rean_dir = [root_dir file_prefix{ifile} '_'];
    [SWE_POST, SWE_POST_std] = ...
        load_basin_wide_post_SWE_mean_and_std(coords,WY,rean_dir,aso_dir);
    eval([file_prefix{ifile} '_post.SWE = SWE_POST;']);
    eval([file_prefix{ifile} '_post.SWE_std = SWE_POST_std;']);
end
% Load MF posterior SWE mean and standard deviation
rean_dir = [root_dir 'mixed_RMSE_weight_'];
[MF_SWE_POST, MF_SWE_POST_std] = ...
    load_basin_wide_post_SWE_mean_and_std(coords,WY,rean_dir,aso_dir);
MF_post.SWE = MF_SWE_POST;
MF_post.SWE_std = MF_SWE_POST_std;

% Benefit of MF for uncertainty characterization
RESULTS_uncertainty = generate_MF_uncertainty_benefit(ERA5_post,MERRA2_post, ...
    NLDAS2_post,MF_post,ASO_data,ASO_SWE_adjusted, ...
    mask,WY,2);