function STATS = generate_MF_stats_figure( ...
    ERA5, MERRA2, NLDAS2, MF, ...
    ASO_data, ASO_SWE_adjusted, mask, WY, basin_name, output_file)
% generate_MF_stats_figure
%
% Plot RMSE, absolute bias, and ubRMSE for ERA5, MERRA2, NLDAS2,
% and multi-forcing SWE estimates.
%
% Figure layout:
%
%   Row 1: RMSE
%   Row 2: |Bias|
%   Row 3: ubRMSE
%
%   Left column:  statistics for each ASO observation date
%   Right column: overall statistics across all ASO dates and valid pixels
%
% INPUTS
%   ERA5, MERRA2, NLDAS2, MF
%       Structures containing daily SWE maps:
%       ERA5.SWE
%       MERRA2.SWE
%       NLDAS2.SWE
%       MF.SWE
%
%   ASO_data
%       Structure created by create_ASO_data_structure.m
%
%   ASO_SWE_adjusted
%       Adjusted ASO SWE maps:
%       rows x columns x number of ASO dates
%
%   mask
%       Basin mask:
%       valid pixels = 1
%       pixels outside the basin = NaN
%
%   WY
%       Water year, for example:
%       2019
%
%   basin_name
%       Display name, for example:
%       'Merced'
%
%   output_file
%       Optional PNG output path.
%       Use '' when you do not want to save the figure.
%
% OUTPUT
%   STATS
%       Structure containing statistics for each date and overall.
%
% EXAMPLE
%   STATS = generate_MF_stats_figure( ...
%       ERA5, MERRA2, NLDAS2, MF, ...
%       ASO_data, ASO_SWE_adjusted, mask, WY, ...
%       'Merced', 'Merced_MF_stats.png');

%% Optional inputs
if nargin < 9 || isempty(basin_name)
    basin_name = '';
end

if nargin < 10
    output_file = '';
end

%% Settings
forcing_names = { ...
    'ERA5', ...
    'MERRA2', ...
    'NLDAS2', ...
    'MF'};

forcing_data = { ...
    ERA5.SWE, ...
    MERRA2.SWE, ...
    NLDAS2.SWE, ...
    MF.SWE};

forcing_colors = [ ...
    0.000, 0.447, 0.741; ... % ERA5
    0.850, 0.325, 0.098; ... % MERRA2
    0.494, 0.184, 0.556; ... % NLDAS2
    0.466, 0.674, 0.188];    % Multi-forcing

Nforcings = numel(forcing_names);

%% Read ASO dates
WY_str = sprintf('%d_%02d', WY - 1, mod(WY, 100));

dowy_field = ['ASO_DOWY_WY' WY_str];

ASO_dowy = ASO_data.(dowy_field);

Ndays = numel(ASO_dowy);

%% Create x-axis date labels
date_labels = create_date_labels( ...
    ASO_data, ...
    ASO_dowy, ...
    WY, ...
    WY_str);

%% Preallocate statistics
RMSE = nan(Ndays, Nforcings);

bias = nan(Ndays, Nforcings);

ubRMSE = nan(Ndays, Nforcings);

all_diff = cell(Nforcings, 1);

for iforcing = 1:Nforcings
    all_diff{iforcing} = [];
end

%% Calculate statistics for each ASO date
for iday = 1:Ndays

    ASO_map = squeeze( ...
        ASO_SWE_adjusted(:, :, iday));

    ASO_map(isnan(mask)) = nan;

    for iforcing = 1:Nforcings

        model_map = squeeze( ...
            forcing_data{iforcing}(:, :, ASO_dowy(iday)));

        model_map(isnan(mask)) = nan;

        valid_id = ...
            ~isnan(model_map) & ...
            ~isnan(ASO_map) & ...
            ~isinf(model_map) & ...
            ~isinf(ASO_map);

        diff_values = ...
            model_map(valid_id) - ...
            ASO_map(valid_id);

        if isempty(diff_values)

            warning( ...
                'No valid pixels for %s on ASO date %d.', ...
                forcing_names{iforcing}, ...
                iday);

            continue;

        end

        bias(iday, iforcing) = ...
            mean(diff_values);

        RMSE(iday, iforcing) = ...
            sqrt(mean(diff_values .^ 2));

        ubRMSE_squared = ...
            RMSE(iday, iforcing) ^ 2 - ...
            bias(iday, iforcing) ^ 2;

        ubRMSE(iday, iforcing) = ...
            sqrt(max(ubRMSE_squared, 0));

        all_diff{iforcing} = [ ...
            all_diff{iforcing}; ...
            diff_values(:)]; 

    end

end

abs_bias = abs(bias);

%% Calculate overall statistics
overall_RMSE = nan(1, Nforcings);

overall_bias = nan(1, Nforcings);

overall_abs_bias = nan(1, Nforcings);

overall_ubRMSE = nan(1, Nforcings);

for iforcing = 1:Nforcings

    diff_values = all_diff{iforcing};

    overall_bias(iforcing) = ...
        mean(diff_values, 'omitnan');

    overall_abs_bias(iforcing) = ...
        abs(overall_bias(iforcing));

    overall_RMSE(iforcing) = ...
        sqrt(mean(diff_values .^ 2, 'omitnan'));

    ubRMSE_squared = ...
        overall_RMSE(iforcing) ^ 2 - ...
        overall_bias(iforcing) ^ 2;

    overall_ubRMSE(iforcing) = ...
        sqrt(max(ubRMSE_squared, 0));

end

%% Determine shared y-axis limits
rmse_max = get_axis_limit( ...
    RMSE, ...
    overall_RMSE);

bias_max = get_axis_limit( ...
    abs_bias, ...
    overall_abs_bias);

ubrmse_max = get_axis_limit( ...
    ubRMSE, ...
    overall_ubRMSE);

%% Create figure
fig = figure( ...
    'Color', ...
    'w', ...
    'Position', ...
    [100, 100, 900, 820]);

layout = tiledlayout( ...
    3, ...
    2, ...
    'TileSpacing', ...
    'compact', ...
    'Padding', ...
    'compact');

%% Row 1: RMSE
ax1 = nexttile;

legend_handles = plot_date_panel( ...
    ax1, ...
    RMSE, ...
    date_labels, ...
    forcing_colors, ...
    rmse_max);

ylabel(ax1, 'RMSE (m)');

title(ax1, basin_name);

ax2 = nexttile;

plot_overall_panel( ...
    ax2, ...
    overall_RMSE, ...
    forcing_colors, ...
    rmse_max);

title(ax2, 'Overall');

%% Row 2: absolute bias
ax3 = nexttile;

plot_date_panel( ...
    ax3, ...
    abs_bias, ...
    date_labels, ...
    forcing_colors, ...
    bias_max);

ylabel(ax3, '|Bias| (m)');

ax4 = nexttile;

plot_overall_panel( ...
    ax4, ...
    overall_abs_bias, ...
    forcing_colors, ...
    bias_max);

%% Row 3: unbiased RMSE
ax5 = nexttile;

plot_date_panel( ...
    ax5, ...
    ubRMSE, ...
    date_labels, ...
    forcing_colors, ...
    ubrmse_max);

ylabel(ax5, 'ubRMSE (m)');

ax6 = nexttile;

plot_overall_panel( ...
    ax6, ...
    overall_ubRMSE, ...
    forcing_colors, ...
    ubrmse_max);

%% Shared legend
lgd = legend( ...
    legend_handles, ...
    forcing_names, ...
    'NumColumns', ...
    4, ...
    'Location', ...
    'southoutside');

lgd.Layout.Tile = 'south';

%% Save figure when requested
if ~isempty(output_file)

    exportgraphics( ...
        fig, ...
        output_file, ...
        'Resolution', ...
        300);

    fprintf('Saved figure:\n%s\n', output_file);

end

%% Return statistics
STATS.RMSE = RMSE;

STATS.bias = bias;

STATS.abs_bias = abs_bias;

STATS.ubRMSE = ubRMSE;

STATS.overall_RMSE = overall_RMSE;

STATS.overall_bias = overall_bias;

STATS.overall_abs_bias = overall_abs_bias;

STATS.overall_ubRMSE = overall_ubRMSE;

STATS.ASO_dowy = ASO_dowy;

STATS.date_labels = date_labels;

STATS.forcing_names = forcing_names;

end

%% Plot grouped bars for individual ASO dates
function bar_handles = plot_date_panel( ...
    ax, stats, date_labels, forcing_colors, y_max)

Ndays = size(stats, 1);

Nforcings = size(stats, 2);

x = 1:Ndays;

hold(ax, 'on');

%% Shade the first ASO date
patch( ...
    ax, ...
    [0.6, 1.4, 1.4, 0.6], ...
    [0, 0, y_max, y_max], ...
    [0.90, 0.90, 0.90], ...
    'EdgeColor', ...
    'none');

%% Plot bars
bar_handles = bar( ...
    ax, ...
    x, ...
    stats, ...
    'grouped');

for iforcing = 1:Nforcings

    bar_handles(iforcing).FaceColor = ...
        forcing_colors(iforcing, :);

end

%% Axis formatting
xlim(ax, [0.5, Ndays + 0.5]);

ylim(ax, [0, y_max]);

xticks(ax, x);

xticklabels(ax, date_labels);

box(ax, 'on');

grid(ax, 'on');

set( ...
    ax, ...
    'FontName', ...
    'Arial', ...
    'FontSize', ...
    11, ...
    'FontWeight', ...
    'bold', ...
    'LineWidth', ...
    0.75);

end

%% Plot overall bars
function plot_overall_panel( ...
    ax, stats, forcing_colors, y_max)

hold(ax, 'on');

b = bar( ...
    ax, ...
    stats);

b.FaceColor = 'flat';

b.CData = forcing_colors;

xlim(ax, [0.5, numel(stats) + 0.5]);

ylim(ax, [0, y_max]);

xticks(ax, []);

box(ax, 'on');

grid(ax, 'on');

%% Add values above bars
x_position = b.XEndPoints;

y_position = b.YEndPoints;

labels = string(round(y_position, 2));

text( ...
    ax, ...
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

set( ...
    ax, ...
    'FontName', ...
    'Arial', ...
    'FontSize', ...
    11, ...
    'FontWeight', ...
    'bold', ...
    'LineWidth', ...
    0.75);

end

%% Calculate a rounded y-axis limit
function y_max = get_axis_limit(stats, overall_stats)

all_values = [ ...
    stats(:); ...
    overall_stats(:)];

y_max = max( ...
    all_values, ...
    [], ...
    'omitnan');

y_max = ceil(y_max * 10) / 10;

if isempty(y_max) || isnan(y_max) || y_max == 0
    y_max = 0.1;
end

end

%% Create labels such as Mar-29 and Jun-04
function date_labels = create_date_labels( ...
    ASO_data, ASO_dowy, WY, WY_str)

date_field = ['ASO_dates_WY' WY_str];

if isfield(ASO_data, date_field)

    observation_dates = ASO_data.(date_field);

else

    water_year_start = datetime( ...
        WY - 1, ...
        10, ...
        1);

    observation_dates = ...
        water_year_start + ...
        days(ASO_dowy - 1);

end

date_labels = cell( ...
    numel(observation_dates), ...
    1);

for iday = 1:numel(observation_dates)

    date_labels{iday} = datestr( ...
        observation_dates(iday), ...
        'mmm-dd');

end

end