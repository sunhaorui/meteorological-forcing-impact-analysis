function RESULTS = generate_MF_uncertainty_benefit( ...
    ERA5, MERRA2, NLDAS2, MF, ...
    ASO_data, ASO_SWE_adjusted, mask, WY, day_id, output_file)
% generate_MF_uncertainty_benefit
%
% Plot the fraction of basin pixels where adjusted ASO SWE falls within
% the posterior SWE uncertainty interval:
%
%   posterior SWE mean - 2 * posterior SWE standard deviation
%   posterior SWE mean + 2 * posterior SWE standard deviation
%
% The figure compares ERA5, MERRA2, NLDAS2, and multi-forcing (MF).
%
% REQUIRED STRUCTURE FIELDS
%   ERA5.SWE
%   ERA5.SWE_std
%
%   MERRA2.SWE
%   MERRA2.SWE_std
%
%   NLDAS2.SWE
%   NLDAS2.SWE_std
%
%   MF.SWE
%   MF.SWE_std
%
% Each SWE array must have dimensions:
%
%   rows x columns x day of water year
%
% INPUTS
%   ASO_data
%       Structure created by create_ASO_data_structure.m
%
%   ASO_SWE_adjusted
%       Adjusted ASO SWE maps:
%       rows x columns x number of ASO observation dates
%
%   mask
%       Basin mask:
%       valid basin pixels = 1
%       pixels outside the basin = NaN
%
%   WY
%       Water year, for example:
%       2019
%
%   day_id
%       Index of the ASO observation date to plot.
%       The default is 2, matching the June-date comparison in the
%       original analysis script.
%
%   output_file
%       Optional PNG output path.
%       Use '' when the figure should not be saved.
%
% OUTPUT
%   RESULTS
%       Structure containing uncertainty-coverage ratios and binary maps.
%
% EXAMPLE
%   RESULTS = generate_MF_uncertainty_benefit( ...
%       ERA5_post, ...
%       MERRA2_post, ...
%       NLDAS2_post, ...
%       MF_post, ...
%       ASO_data, ...
%       ASO_SWE_adjusted, ...
%       mask, ...
%       2019, ...
%       2, ...
%       'Merced_MF_uncertainty_benefit.png');

%% Optional inputs
if nargin < 9 || isempty(day_id)
    day_id = 2;
end

if nargin < 10
    output_file = '';
end

%% Settings
dataset_names = { ...
    'ERA5', ...
    'MERRA2', ...
    'NLDAS2', ...
    'Multi-forcing'};

dataset_structures = { ...
    ERA5, ...
    MERRA2, ...
    NLDAS2, ...
    MF};

dataset_colors = [ ...
    0.0000, 0.4470, 0.7410; ... % ERA5
    0.8500, 0.3250, 0.0980; ... % MERRA2
    0.4940, 0.1840, 0.5560; ... % NLDAS2
    0.4660, 0.6740, 0.1880];    % Multi-forcing

Ndatasets = numel(dataset_names);

%% Read ASO observation dates
WY_str = sprintf( ...
    '%d_%02d', ...
    WY - 1, ...
    mod(WY, 100));

dowy_field = [ ...
    'ASO_DOWY_WY' ...
    WY_str];

ASO_dowy = ASO_data.(dowy_field);

Ndays = numel(ASO_dowy);
%% Extract ASO SWE for selected observation date
ASO_map = squeeze( ...
    ASO_SWE_adjusted(:, :, day_id));

ASO_map(isnan(mask)) = nan;

selected_dowy = ASO_dowy(day_id);

%% Preallocate outputs
coverage_ratio = nan(1, Ndatasets);

catch_maps = cell(1, Ndatasets);

lower_maps = cell(1, Ndatasets);

upper_maps = cell(1, Ndatasets);

%% Calculate uncertainty coverage
for idataset = 1:Ndatasets

    dataset = dataset_structures{idataset};

    if ~isfield(dataset, 'SWE')

        error( ...
            'Missing field %s.SWE', ...
            dataset_names{idataset});

    end

    if ~isfield(dataset, 'SWE_std')

        error( ...
            'Missing field %s.SWE_std', ...
            dataset_names{idataset});

    end

    %% Extract posterior mean and standard deviation
    SWE_mean = squeeze( ...
        dataset.SWE(:, :, selected_dowy));

    SWE_std = squeeze( ...
        dataset.SWE_std(:, :, selected_dowy));

    %% Calculate uncertainty bounds
    SWE_lower = ...
        SWE_mean - ...
        2 .* SWE_std;

    SWE_upper = ...
        SWE_mean + ...
        2 .* SWE_std;

    %% Create binary catch map
    %
    % 1 = adjusted ASO SWE falls inside the posterior uncertainty interval
    % 0 = adjusted ASO SWE falls outside the posterior uncertainty interval
    % NaN = outside the basin

    catch_map = nan(size(mask));

    catch_map(mask == 1) = 0;

    caught_pixels = ...
        mask == 1 & ...
        ASO_map >= SWE_lower & ...
        ASO_map <= SWE_upper;

    catch_map(caught_pixels) = 1;

    %% Calculate the fraction of basin pixels captured by the interval
    coverage_ratio(idataset) = ...
        sum(catch_map(:), 'omitnan') ./ ...
        sum(mask(:), 'omitnan');

    %% Save maps
    catch_maps{idataset} = catch_map;

    lower_maps{idataset} = SWE_lower;

    upper_maps{idataset} = SWE_upper;

end

%% Create date label
date_label = create_date_label( ...
    ASO_data, ...
    selected_dowy, ...
    day_id, ...
    WY, ...
    WY_str);

%% Plot bar chart
fig = figure( ...
    'Color', ...
    'w', ...
    'Position', ...
    [200, 200, 360, 280]);

b = bar( ...
    coverage_ratio, ...
    'FaceColor', ...
    'flat');

b.CData = dataset_colors;

%% Add numeric labels above bars
x_position = b.XEndPoints;

y_position = b.YEndPoints;

labels = compose( ...
    '%.2f', ...
    coverage_ratio);

text( ...
    x_position, ...
    y_position, ...
    labels, ...
    'HorizontalAlignment', ...
    'center', ...
    'VerticalAlignment', ...
    'bottom', ...
    'FontWeight', ...
    'bold', ...
    'FontSize', ...
    10);

%% Format axes
ylim([0, 1]);

xlim([0.4, Ndatasets + 0.6]);

xticks(1:Ndatasets);

xticklabels({ ...
    'ERA5', ...
    'MERRA2', ...
    'NLDAS2', ...
    'MF'});

ylabel('Fraction of basin pixels');

title({ ...
    'ASO SWE captured by posterior uncertainty interval', ...
    date_label});

box on;

grid on;

set( ...
    gca, ...
    'FontName', ...
    'Arial', ...
    'FontSize', ...
    11, ...
    'FontWeight', ...
    'bold', ...
    'LineWidth', ...
    0.75);

%% Save figure when requested
if ~isempty(output_file)

    exportgraphics( ...
        fig, ...
        output_file, ...
        'Resolution', ...
        300);

    fprintf('Saved figure:\n%s\n', output_file);

end

%% Return results
RESULTS.coverage_ratio = coverage_ratio;

RESULTS.catch_maps = catch_maps;

RESULTS.lower_maps = lower_maps;

RESULTS.upper_maps = upper_maps;

RESULTS.dataset_names = dataset_names;

RESULTS.ASO_dowy = ASO_dowy;

RESULTS.selected_day_id = day_id;

RESULTS.selected_dowy = selected_dowy;

RESULTS.date_label = date_label;

end

%% Local function: create date label
function date_label = create_date_label( ...
    ASO_data, selected_dowy, day_id, WY, WY_str)

date_field = [ ...
    'ASO_dates_WY' ...
    WY_str];

if isfield(ASO_data, date_field)

    observation_dates = ...
        ASO_data.(date_field);

    observation_date = ...
        observation_dates(day_id);

else

    water_year_start = datetime( ...
        WY - 1, ...
        10, ...
        1);

    observation_date = ...
        water_year_start + ...
        days(selected_dowy - 1);

end

date_label = datestr( ...
    observation_date, ...
    'mmm-dd-yyyy');

end