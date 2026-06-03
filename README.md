# Meteorological Forcing Impact Analysis

This repository contains the MATLAB code used to assess the impacts of meteorological forcing and its uncertainty on snow modeling and reanalysis. The scripts are provided to reproduce the analyses and figures presented in:

**Sun, H., and Margulis, S. A.**
*Assessing the Impact of Meteorological Forcing and Its Uncertainty on Snow Modeling and Reanalysis*

## Data Availability

The reanalysis output data and Airborne Snow Observatory (ASO) verification data used by the scripts are archived on Zenodo.

Download the data from:

**Zenodo DOI:** https://doi.org/10.5281/zenodo.20533477

## Code Overview

The repository includes MATLAB scripts for:

* Loading prior and posterior snow water equivalent (SWE) and snow-depth data
* Processing ASO verification data
* Adjusting ASO SWE estimates using modeled snow density
* Generating basin-scale time-series analyses
* Evaluating meteorological-forcing uncertainty
* Producing spatial comparison plots and error maps
* Reproducing the figures presented in the paper

The main entry point is:

```matlab
main_driver.m
```

## Requirements

The analysis was developed in MATLAB. Before running the scripts, download the Zenodo dataset and update any local file paths in the code as needed.

## Usage

1. Download the data archive from Zenodo.
2. Extract the downloaded files.
3. Update the data paths in `main_driver.m` if necessary.
4. Run:

```matlab
main_driver
```

## Citation

When using this code or the associated dataset, please cite the paper and the Zenodo archive.
