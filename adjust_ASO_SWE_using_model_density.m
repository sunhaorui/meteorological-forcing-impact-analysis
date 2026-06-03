function [ASO_SWE_adjusted] = adjust_ASO_SWE_using_model_density(ERA5,MERRA2,NLDAS2,ASO_data,mask)
ASO_dowy = ASO_data.ASO_DOWY_WY2018_19;
ASO_SD = ASO_data.SD_ASO_WY2018_19;
ASO_SWE = ASO_data.SWE_ASO_WY2018_19;
% Compute densities ON snapshot days only
ERA5_den   = squeeze(ERA5.SWE(:,:,ASO_dowy))   ./ squeeze(ERA5.SD(:,:,ASO_dowy));
MERRA2_den = squeeze(MERRA2.SWE(:,:,ASO_dowy)) ./ squeeze(MERRA2.SD(:,:,ASO_dowy));
NLDAS2_den = squeeze(NLDAS2.SWE(:,:,ASO_dowy)) ./ squeeze(NLDAS2.SD(:,:,ASO_dowy));

% 3) Adjust ASO SWE using mean density
ASO_SWE_adjusted   = nan(size(ASO_SWE));

for iday = 1:length(ASO_dowy)
    den_E = squeeze(ERA5_den(:,:,iday));
    den_M = squeeze(MERRA2_den(:,:,iday));
    den_N = squeeze(NLDAS2_den(:,:,iday));
    den_A = (den_E + den_M + den_N) / 3;
    ASO_SWE_adjusted(:,:,iday)   = squeeze(ASO_SD(:,:,iday)) .* den_A;
end

% if adjusted is NaN but ASO_SWE is valid, use ASO_SWE
id = find(isnan(ASO_SWE_adjusted)   & ASO_SWE >= 0); ASO_SWE_adjusted(id)   = ASO_SWE(id);

for iday = 1:size(ASO_SWE_adjusted,3)
    tmp = squeeze(ASO_SWE_adjusted(:,:,iday));
    tmp(isnan(mask))=nan;
    ASO_SWE_adjusted(:,:,iday) = tmp;
end
end