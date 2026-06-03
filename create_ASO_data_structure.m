function ASO_data = create_ASO_data_structure(aso_dir,WY)
% find SWE and SD files
swe_pattern = sprintf('ASO_SWE_USCAMB_*_agg_5.mat');
sd_pattern = sprintf('ASO_SD_USCAMB_*_agg_5.mat');

swe_files = dir(fullfile(aso_dir,swe_pattern));
sd_files = dir(fullfile(aso_dir,sd_pattern));

% extract dates from filenames and sort files
[swe_dates,swe_files] = sort_files_by_date(swe_files);
[sd_dates,sd_files] = sort_files_by_date(sd_files);
observation_dates = swe_dates;
ndates = numel(observation_dates);

% load aso data (first date) to determine dimensions
first_swe_files = fullfile(swe_files(1).folder,swe_files(1).name);
load(first_swe_files);
nrows = size(aso_data_agg,1); 
ncols = size(aso_data_agg,2);

% Preallocate arrays
SWE = nan(nrows,ncols,ndates);
SD = nan(nrows,ncols,ndates);
% load maps for each date
for idate = 1:ndates
    swe_file = fullfile(swe_files(idate).folder,swe_files(idate).name);
    load(swe_file);
    SWE(:,:,idate) = aso_data_agg;
    
    sd_file = fullfile(sd_files(idate).folder,sd_files(idate).name);
    load(sd_file);
    SD(:,:,idate) = aso_data_agg;
end
%% Calculate day of water year
% Day 1 of the water year is October 1 of the previous calendar year.
water_year_start = datetime(WY - 1, 10, 1);
dowy = days(observation_dates - water_year_start) + 1;
dowy = double(dowy(:));
%% Create field names
WY_str = sprintf('%d_%02d', ...
    WY - 1, ...
    mod(WY, 100));

swe_field = ['SWE_ASO_WY' WY_str];

sd_field = ['SD_ASO_WY' WY_str];

dowy_field = ['ASO_DOWY_WY' WY_str];

date_field = ['ASO_dates_WY' WY_str];

%% Create ASO_data structure
ASO_data = struct();

ASO_data.(swe_field) = SWE;

ASO_data.(sd_field) = SD;

ASO_data.(dowy_field) = dowy;

ASO_data.(date_field) = observation_dates;

ASO_data.water_year = WY;

end

function [dates,files]=sort_files_by_date(files)
nfiles = numel(files);
dates = NaT(nfiles,1);
for ifile = 1:nfiles
    token = regexp(files(ifile).name,'_(\d{8})_agg_','tokens','once');
    dates(ifile) = datetime(token{1},'InputFormat','yyyyMMdd');
end
[dates,sort_id] = sort(dates);
files = files(sort_id);
end