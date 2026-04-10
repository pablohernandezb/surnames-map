# Surnames Map of Venezuela

A geospatial visualization project that maps the most common surnames in each state of Venezuela using word clouds overlaid on geographic boundaries. Surnames are sized proportionally to their frequency in each region.

![Surnames Map of Venezuela (English)](surnames_map_VE_en.png)

## Overview

This project processes Venezuela's Permanent Electoral Registry (CNE, January 2024) to extract first surnames by state, then renders them as word cloud maps where each state's boundary contains its most frequent surnames. The project includes both Python and R implementations, and a final SVG for post-processing in Inkscape.

## Data Source

The raw data comes from Venezuela's Electoral Registry (`rep_01_2024.dta`, ~2.1 GB Stata file). Due to its size, it is not included in this repository. The processed aggregate dataset (`lastname_state_counts.csv`) is also excluded via `.gitignore`.

## Workflow

### 1. Generate the Dataset (R)

Run `generating_dataset.R` to process the raw electoral data and produce `lastname_state_counts.csv`, which maps each state to its surname frequency counts.

```r
source("generating_dataset.R")
```

**Output:** `lastname_state_counts.csv` — ~359,000 rows with columns `state_id`, `first_lastname`, `count`.

### 2. Generate the Map

Two implementations are available:

**Python** — renders word clouds directly within state-shaped masks:

```bash
python surnames_map.py
```

Output: `figure_output3.png` (50×50 in, 400 DPI)

**R** — places word clouds at state centroids using `ggwordcloud`:

```r
source("surnames_map.R")
```

Output: `venezuela_lastname_map.png` (14×10 in, 300 DPI)

### 3. Post-processing (Optional)

The file `surnames_map_VE.svg` can be edited in Inkscape to add annotations, legends, or layout adjustments, then exported to PNG.

## Dependencies

**Python:**

```
pandas
geopandas
matplotlib
wordcloud
Pillow
numpy
```

**R:**

```r
install.packages(c("sf", "tidyverse", "ggplot2", "ggwordcloud", "haven", "dplyr", "stringr"))
```

## Repository Structure

```
surnames-map/
├── surnames_map.py          # Python map generation script
├── surnames_map.R           # R map generation script
├── generating_dataset.R     # Data processing script (raw → CSV)
├── state_id_names.csv       # State ID to name mapping
├── Estados_Venezuela.shp    # Venezuela state boundaries (shapefile)
├── Trujillo-Bold.ttf        # Font used in visualizations
├── surnames_map_VE.svg      # Editable vector version
├── surnames_map_VE_en.png   # Final map (English)
└── surnames_map_VE_es.png   # Final map (Spanish)
```

## Output

| File | Description |
|------|-------------|
| `surnames_map_VE_en.png` | Final high-resolution map in English |
| `surnames_map_VE_es.png` | Final high-resolution map in Spanish |
| `surnames_map_VE.svg` | Editable vector version |
