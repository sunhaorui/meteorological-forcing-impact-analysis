function STATS = generate_spatial_SWE_comparison_bars( ...
    ERA5, MERRA2, NLDAS2, ASO_data, ASO_SWE_adjusted, mask, WY)
% generate_spatial_SWE_comparison_bars
%
% Generate grouped stacked bars showing the spatial SWE error components:
%
%   RMSE^2 = bias^2 + ubRMSE^2
%
% Each ASO observation date is one group.
% Each group contains three stacked bars:
%   ERA5, MERRA2, and NLDAS2.
%
% The right axis shows:
%
%   bias^2 / RMSE^2
%
% INPUTS
%   ERA5, MERRA2, NLDAS2
%       Structures containing daily prior SWE maps:
%       ERA5.SWE
%       MERRA2.SWE
%       NLDAS2.SWE
%
%   ASO_data
%       Structure created by create_ASO_data_structure.m
%
%   ASO_SWE_adjusted
%       Adjusted ASO SWE maps:
%       rows x columns x ASO observation dates
%
%   mask
%       Basin mask:
%       valid pixels = 1
%       pixels outside basin = NaN
%
%   WY
%       Water year, for example:
%       WY = 2019
%
% OUTPUT
%   STATS
%       Structure containing bias^2, ubRMSE^2, RMSE^2, and bias ratios.
%
% EXAMPLE
%   STATS = generate_spatial_SWE_comparison_bars( ...
%       ERA5, MERRA2, NLDAS2, ...
%       ASO_data, ASO_SWE_adjusted, mask, 2019);

%% Water-year field names
WY_str = sprintf('%d_%02d', WY - 1, mod(WY, 100));

dowy_field = ['ASO_DOWY_WY' WY_str];

ASO_dowy = ASO_data.(dowy_field);

Ndays = numel(ASO_dowy);

%% Store forcing datasets
forcing_names = {'ERA5', 'MERRA2', 'NLDAS2'};

forcing_SWE = { ...
    ERA5.SWE, ...
    MERRA2.SWE, ...
    NLDAS2.SWE};

Nforcing = numel(forcing_names);

%% Preallocate statistics
bias_squared = nan(Ndays, Nforcing);

ubRMSE_squared = nan(Ndays, Nforcing);

RMSE_squared = nan(Ndays, Nforcing);

bias_ratio = nan(Ndays, Nforcing);

%% Calculate spatial error statistics
for iday = 1:Ndays

    ASO_map = squeeze( ...
        ASO_SWE_adjusted(:, :, iday));

    for iforcing = 1:Nforcing

        model_map = squeeze( ...
            forcing_SWE{iforcing}(:, :, ASO_dowy(iday)));

        %% Calculate spatial SWE error
        error_map = model_map - ASO_map;

        %% Apply basin mask and remove invalid values
        error_map(isnan(mask)) = nan;

        error_vector = error_map(:);

        error_vector = error_vector( ...
            ~isnan(error_vector) & ...
            ~isinf(error_vector));

        %% Calculate RMSE decomposition
        spatial_bias = mean(error_vector);

        bias_squared(iday, iforcing) = ...
            spatial_bias ^ 2;

        RMSE_squared(iday, iforcing) = ...
            mean(error_vector .^ 2);

        ubRMSE_squared(iday, iforcing) = ...
            RMSE_squared(iday, iforcing) - ...
            bias_squared(iday, iforcing);

        %% Prevent small negative values caused by floating-point rounding
        ubRMSE_squared(iday, iforcing) = max( ...
            ubRMSE_squared(iday, iforcing), ...
            0);

        %% Calculate bias contribution to RMSE squared
        if RMSE_squared(iday, iforcing) > 0

            bias_ratio(iday, iforcing) = ...
                bias_squared(iday, iforcing) ./ ...
                RMSE_squared(iday, iforcing);

        end

    end

end

%% Create x-axis labels
date_labels = create_date_labels( ...
    ASO_data, ...
    ASO_dowy, ...
    WY, ...
    WY_str);

%% Plot settings
forcing_colors = [ ...
    0.0000, 0.4470, 0.7410; ... % ERA5
    0.8500, 0.3250, 0.0980; ... % MERRA2
    0.4940, 0.1840, 0.5560];    % NLDAS2

light_colors = [ ...
    0.60, 0.80, 0.95; ... % ERA5 ubRMSE^2
    0.95, 0.75, 0.65; ... % MERRA2 ubRMSE^2
    0.82, 0.70, 0.90];    % NLDAS2 ubRMSE^2

group_centers = 1:Ndays;

bar_offsets = [-0.23, 0, 0.23];

bar_width = 0.20;

%% Create figure
figure('Color', 'w', 'Position', ...
    [200, 200, 150 * Ndays + 250, 430]);

ax = gca;
hold(ax, 'on');
box(ax, 'on');
grid(ax, 'on');

%% Plot grouped stacked bars
legend_handles = gobjects(6, 1);

for iforcing = 1:Nforcing

    x_position = group_centers + ...
        bar_offsets(iforcing);

    stacked_values = [ ...
        bias_squared(:, iforcing), ...
        ubRMSE_squared(:, iforcing)];

    h = bar( ...
        ax, ...
        x_position, ...
        stacked_values, ...
        bar_width, ...
        'stacked');

    h(1).FaceColor = forcing_colors(iforcing, :);

    h(2).FaceColor = light_colors(iforcing, :);

    legend_handles((iforcing - 1) * 2 + 1) = h(1);

    legend_handles((iforcing - 1) * 2 + 2) = h(2);

end

%% Configure left axis
ylabel('RMSE^2 (m^2)');

xlim([0.5, Ndays + 0.5]);

xticks(group_centers);

xticklabels(date_labels);

set( ...
    ax, ...
    'FontName', ...
    'Arial', ...
    'FontSize', ...
    12, ...
    'FontWeight', ...
    'bold', ...
    'LineWidth', ...
    0.75);

%% Add legend
legend( ...
    legend_handles, ...
    { ...
        'ERA5 bias^2', ...
        'ERA5 ubRMSE^2', ...
        'MERRA2 bias^2', ...
        'MERRA2 ubRMSE^2', ...
        'NLDAS2 bias^2', ...
        'NLDAS2 ubRMSE^2'}, ...
    'Location', ...
    'southoutside', ...
    'NumColumns', ...
    3);

%% Overlay bias ratio
yyaxis right;

hold on;

ratio_handles = gobjects(Nforcing, 1);

for iforcing = 1:Nforcing

    x_position = group_centers + ...
        bar_offsets(iforcing);

    ratio_handles(iforcing) = plot( ...
        x_position, ...
        bias_ratio(:, iforcing), ...
        'o', ...
        'MarkerFaceColor', ...
        forcing_colors(iforcing, :), ...
        'MarkerEdgeColor', ...
        forcing_colors(iforcing, :), ...
        'MarkerSize', ...
        6, ...
        'LineStyle', ...
        'none');

end

ylabel('bias^2 / RMSE^2');

ylim([0, 1]);

yticks([0, 0.5, 1]);

%% Title
title(sprintf( ...
    'Spatial SWE error decomposition, WY%d', ...
    WY));

%% Return results
STATS.bias_squared = bias_squared;

STATS.ubRMSE_squared = ubRMSE_squared;

STATS.RMSE_squared = RMSE_squared;

STATS.bias_ratio = bias_ratio;

STATS.ASO_dowy = ASO_dowy;

STATS.date_labels = date_labels;

STATS.forcing_names = forcing_names;

end

%% Local function: generate x-axis date labels
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

    observation_dates = water_year_start + ...
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