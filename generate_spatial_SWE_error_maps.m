function generate_spatial_SWE_error_maps( ...
    ERA5, MERRA2, NLDAS2, ASO_data, ASO_SWE_adjusted, mask,lat,lon, WY)
% generate_spatial_SWE_error_maps
%
% Plot spatial maps of prior SWE error:
%
%   SWE error = prior SWE - adjusted ASO SWE
%
% Positive values indicate that the reanalysis estimate is larger than ASO.
% Negative values indicate that the reanalysis estimate is smaller than ASO.
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
%       Basin mask. Valid basin pixels should equal 1.
%       Pixels outside the basin should be NaN.
%
%   WY
%       Water year, for example:
%       WY = 2019
%
% EXAMPLE
%   generate_spatial_SWE_error_maps( ...
%       ERA5, ...
%       MERRA2, ...
%       NLDAS2, ...
%       ASO_data, ...
%       ASO_SWE_adjusted, ...
%       mask, ...
%       2019);

%% Water-year field name
WY_str = sprintf('%d_%02d', WY - 1, mod(WY, 100));
dowy_field = ['ASO_DOWY_WY' WY_str];
ASO_dowy = ASO_data.(dowy_field);
Ndays = numel(ASO_dowy);

%% Store forcing datasets in cell arrays
forcing_names = {'ERA5', 'MERRA2', 'NLDAS2'};

forcing_SWE = { ...
    ERA5.SWE, ...
    MERRA2.SWE, ...
    NLDAS2.SWE};

%% Limit plotting area to the basin domain
Ilat = find(sum(~isnan(mask), 2) > 0);
Ilon = find(sum(~isnan(mask), 1) > 0);
longitude = lon;
latitude = lat;

%% Plot settings
color_range = [-0.8, 0.8];

figure( ...
    'Color', ...
    'w', ...
    'Position', ...
    [100, 100, 300 * Ndays, 750]);

tiledlayout( ...
    3, ...
    Ndays, ...
    'TileSpacing', ...
    'compact', ...
    'Padding', ...
    'compact');

%% Plot SWE error maps
for iforcing = 1:numel(forcing_names)

    for iday = 1:Ndays

        % Extract prior SWE on the ASO observation date
        model_SWE = squeeze( ...
            forcing_SWE{iforcing}(:, :, ASO_dowy(iday)));

        % Extract adjusted ASO SWE
        ASO_SWE = squeeze( ...
            ASO_SWE_adjusted(:, :, iday));

        % Calculate SWE error
        error_map = model_SWE - ASO_SWE;

        % Apply basin mask
        error_map(isnan(mask)) = nan;
        error_map(isinf(error_map)) = nan;

        % Crop to basin domain
        error_map = error_map(Ilat, Ilon);

        % Plot
        nexttile;

        imagesc(longitude, latitude,error_map,'AlphaData',isnan(error_map)==0);
        set(gca,'YDir','normal');
        axis image;
        caxis(color_range);
        grid off;

        % Add column titles
        if iforcing == 1
            title(sprintf( ...
                'DOWY %d', ...
                ASO_dowy(iday)));
        end

        %% Add row labels
        if iday == 1
            ylabel(sprintf( ...
                '%s\nLatitude', ...
                forcing_names{iforcing}));
        else
            set(gca, ...
                'YTickLabel', ...
                []);
        end

        % Add x-axis label to the bottom row
        if iforcing == numel(forcing_names)

            xlabel('Longitude');

        else
            set(gca, ...
                'XTickLabel', ...
                []);
        end

    end

end

% Apply diverging color map
colormap(flipud(red_blue_colormap(101)));
% Add one shared color bar
cb = colorbar;

cb.Layout.Tile = 'east';

cb.Label.String = 'Prior SWE - adjusted ASO SWE (m)';

end

%% Local function: red-white-blue diverging color map
function cmap = red_blue_colormap(ncolors)

if nargin < 1

    ncolors = 101;

end

half = floor(ncolors / 2);

blue_to_white = [ ...
    linspace(0, 1, half)', ...
    linspace(0, 1, half)', ...
    ones(half, 1)];

white_to_red = [ ...
    ones(half + 1, 1), ...
    linspace(1, 0, half + 1)', ...
    linspace(1, 0, half + 1)'];

cmap = [blue_to_white;white_to_red];

end