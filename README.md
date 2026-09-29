# Urban Environmental Footprint Model: Israeli Cities

A MATLAB model for calculating the **carbon, water and land footprints** of individual Israeli cities, and for projecting them to 2030 and 2040 under alternative mitigation scenarios.

This repository contains the code and input data for the M.Sc. thesis:

> **Development of a model to examine and evaluate urban footprints and possible measures for reducing the impact**
> Lidor Tzur. M.Sc. thesis, Department of Industrial Engineering and Management, Faculty of Engineering Sciences, Ben-Gurion University of the Negev, September 2026.
> Supervisors: Prof. Raziel Riemer and Prof. Meidad Kissinger.

---

## Overview

The model is a high-resolution, bottom-up, **consumption-based** footprint model. It downscales the national-scale accounting and projection framework of Cordova et al. (2024) to the level of the individual municipality.

For each city, the model:

1. **Sets a baseline** for the reference year **2019**, including population, per-capita consumption, and emission and resource coefficients.
2. **Projects consumption** from population growth and city-specific per-capita consumption trends.
3. **Activates mitigation levers**, such as renewable electricity, vehicle electrification, public-transit modal shift, low-carbon construction materials, residential density and waste diversion.
4. **Runs three scenarios:** Business-as-Usual (**BAU**), **Moderate** and **Advanced**.
5. **Outputs annual footprints** (GHG emissions, water and land) for every year from the base year to the target year. The thesis reports **2030** and **2040**.

The model also includes a **per-city, per-lever sensitivity (elasticity) analysis**. Each input lever is perturbed by ±10% for every projection year, which produces a ranking of the most effective mitigation levers for each city and each year.

### Consumption sectors

| Sector | Main drivers |
|---|---|
| Electricity | Residential and non-residential consumption; generation mix (gas, renewables/PV) |
| Transportation | City-specific vehicle-km (VKT) and fleet; hot and cold-start emissions; well-to-wheel fuel; EV transition; modal shift |
| Water | Urban water consumption; energy for water supply; sewage emissions |
| Food | National per-capita diet scaled by population; local and global water for food; land for food |
| Construction | Residential and non-residential; high-rise and low-rise typologies; embodied carbon; land take |
| Materials & Waste | Material consumption (cradle-to-gate); landfill, recycling and waste-to-energy |
| Fuel for heat | National per-capita consumption scaled by population |

### Case-study cities

| Typology | Cities |
|---|---|
| Metropolises | Tel Aviv (`Tlv`), Rishon LeZion (`RishonLeZion`), Be'er Sheva (`BeerSheva`) |
| Established Satellites | Ra'anana (`Raanana`), Modi'in (`Modiin`) |
| Growth Cities | Hadera (`Hadera`), Afula (`Afula`), Kiryat Gat (`KiryatGat`) |
| Sectoral & Small | Beit Shemesh (`BeitShemesh`), Rahat (`Rahat`), Sakhnin (`Sakhnin`), Mazkeret Batya (`MazkeretBatya`) |

---

## Repository structure

```
.
├── MainSystem.m              # Entry point: loops over all cities and saves AllCities.mat
├── run_city_once.m           # Runs the model for a single city and exports its result tables
├── createPath.m              # Adds the project folders to the MATLAB path
│
├── Operating/
│   ├── preparation.m         # General inputs (base year 2019, target year 2050, constants) and reading the city Excel
│   ├── ReadValues.m          # Builds the sector databases (DataBase struct) from the Excel sheets
│   └── runningSteps.m        # Mode selection: (1) BAU/Moderate/Advanced, (2) sensitivity analysis
│
├── CalcFunctions/            # Sector calculations (electricity, transport, water, food,
│                             #   construction, materials & waste, EV transition, population, etc.)
│
├── Scenarios/
│   ├── AllButOneChangesByScenarios.m   # Builds the yearly change table for each scenario
│   ├── FullScenario.m                  # Runs all sectors over all years for one scenario
│   ├── ConsumptionChanges.m            # Consumption trends
│   ├── TechnologicalImprovements.m     # Technology levers
│   ├── runSensitivityAnalysis.m        # ±10% sensitivity (single horizon)
│   └── runSensitivityAnalysis_All_Years.m  # ±10% sensitivity for every projection year
│
├── Plots/                    # Result tables for a single city
│
├── Cities_Integrated_Plots/  # Cross-city analysis and thesis figures (read AllCities.mat)
│   ├── helpers/              # Shared helpers (city order and typology, sector colors, table getters)
│   ├── Sensetivity_Plots/    # Elasticity, lever-ranking and scenario-comparison figures
│   └── print for Thesis/     # Scripts for specific thesis figures
│
└── Data/
    ├── <City>.xlsx           # Input data for each city (one workbook per city)
    └── Scenarios_<City>.xlsx # Scenario parameters (BAU / Moderate / Advanced) for each city
```

### Input workbooks

Each `Data/<City>.xlsx` workbook contains the city's baseline data and coefficients, split into sheets: `Population`, `ElectricityConsumption`, `ElectricityManufactureEmissions`, `PVEmissions`, `TransportationConsumption`, `FuelProductionEmissionsForTrans`, `WaterNew`, `Food`, `Construction`, `ConstructionNew`, `Materials`, `Area`, `Money`, `Improvements` and `Scenarios`.

Each `Data/Scenarios_<City>.xlsx` workbook defines the percentage change of every model parameter under each scenario, relative to the 2050 benchmark. Values for intermediate years are interpolated.

---

## Requirements

- **MATLAB R2024a** (the version used in the thesis; earlier recent versions will probably also work).
- **Windows.** File paths in the code use backslashes (for example `Data\Tlv.xlsx`).

---

## How to run

1. Clone the repository and open its root folder in MATLAB as the current folder.
2. Run the whole model for all 12 cities:
   ```matlab
   MainSystem
   ```
   For each city, a dialog asks you to choose a mode:
   - **All the steps together:** runs the BAU, Moderate and Advanced scenarios.
   - **Sensitivity Analysis ±10%:** runs the per-lever elasticity analysis for all years.
3. The results for all cities are gathered in one struct, `AllCities`, and saved to **`AllCities.mat`** in the project root. If `AllCities.mat` already exists, it is loaded first, and new results are merged into it city by city.
4. Result tables for each city are also written to Excel (`TotalResults`, `TotalEmission_BAU`, `TotalEmission_Moderate`, `TotalEmission_Advanced`, or the sensitivity tables).

To run a subset of cities, edit the `cities` list at the top of `MainSystem.m`.

### Producing the figures

After `AllCities.mat` exists, the scripts in `Cities_Integrated_Plots/` produce the cross-city figures used in the thesis. They include baseline snapshots, emissions by sector and typology, per-capita emissions over time, typology clustering, Kruskal-Wallis tests and the sensitivity and lever-ranking figures. Load the data first:

```matlab
load('AllCities.mat', 'AllCities');
Plot_BaseSnapshot
```

### Notes

- **`AllCities.mat` is not included.** The file is about 600 MB, well above GitHub's file size limit. It is regenerated by running `MainSystem`.
- **Output folders point to the author's machine.** Some scripts set their output folder to an absolute path, for example `outDir` in `run_city_once.m` and `outputDir` in the plotting scripts. Change these paths before running on another machine.
- **Generated figures and result workbooks are not tracked in the repository.** Neither are the source documents and literature used to build the input data.

---

## Key results (from the thesis)

- **Carbon varies most between cities.** At baseline, per-capita demand is fairly uniform across the 12 cities. The coefficient of variation across typologies is 4.5% for land, 11.9% for water and 14.1% for carbon.
- **Per-capita emissions fall in every city,** by 29.9–44.2% under the Advanced pathway by 2040.
- **Population growth decides whether total emissions fall.** Cities growing faster than **68.1%** by 2040 see absolute emissions rise even under the Advanced pathway. Under the Moderate pathway the threshold is **41.9%**.
- **Population growth and grid decarbonization dominate the lever ranking** almost everywhere. The ranking of the second-tier levers depends on the city and the year. These include public-transit modal shift, low-carbon construction materials, residential density and waste diversion.

---

## Citation

If you use this model, please cite:

```
Tzur, L. (2026). Development of a model to examine and evaluate urban footprints and
possible measures for reducing the impact. M.Sc. thesis, Department of Industrial
Engineering and Management, Ben-Gurion University of the Negev.
```

The national-scale framework this model builds on:
Cordova et al. (2024).
