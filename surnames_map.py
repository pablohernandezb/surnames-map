import pandas as pd
import geopandas as gpd
import matplotlib.pyplot as plt
from wordcloud import WordCloud
import numpy as np
from PIL import Image, ImageDraw

# 1. Load your local files
# Ensure 'venezuela.shp' is in your working directory
venezuela_map = gpd.read_file('Estados_Venezuela.shp') 

counts_df = pd.read_csv('lastname_state_counts.csv')
names_df = pd.read_csv('state_id_names.csv')

# 2. Merge data to link Surnames to the Shapefile 'ID'
# We link the counts to the names bridge, then we'll use 'shp_state_id' to match 'ID'
full_data = pd.merge(counts_df, names_df, on='state_id')

# 3. Setup the Visuals
fig, ax = plt.subplots(figsize=(50, 50), facecolor="white")
ax.set_aspect('equal')
ax.axis('off')

# Use a high-contrast colormap
colors = plt.cm.get_cmap('Dark2', len(venezuela_map))

# Setting state colors
state_colors = {
    0: (204, 34, 43), # Dtto. Capital
    2: (0, 166, 81), # Anzoátegui
    3: (0, 174, 206), # Apure
    4: (0, 104, 56), # Aragua
    5: (0, 166, 81), # Barinas
    6: (117, 76, 36), # Bolívar
    7: (41, 171, 226), # Carabobo
    8: (218, 28, 92), # Cojedes
    10: (0, 104, 56), # Falcón
    11: (96, 88, 76), # Guárico
    12: (96, 88, 76), # Lara
    13: (0, 104, 56), # Mérida
    14: (46, 49, 146), # Miranda
    15: (218, 28, 92), # Monagas
    16: (0, 166, 81), # Nueva Esparta
    17: (0, 174, 206), # Portuguesa
    18: (0, 114, 188), # Sucre
    19: (236, 0, 140),  # Táchira
    20: (117, 76, 36),  # Trujillo
    22: (102, 45, 145), # Yaracuy
    23: (46, 49, 146), # Zulia
    1: (102, 45, 145), # Amazonas
    9: (102, 45, 145), # Delta Amacuro
    21: (96, 88, 76) # Vargas
}

# 4. Iterative Generation per State
for idx, row in venezuela_map.iterrows():
    # Use 'ID' from shapefile to filter our merged dataframe
    state_geo_id = row['ID'] 
    current_color = state_colors.get(state_geo_id, (0, 0, 0))  # Default to black if not found
    state_geometry = row['geometry']
    
    # Filter surnames for this specific state
    state_subset = full_data[full_data['shp_state_id'] == state_geo_id]
    
    if state_subset.empty:
        continue

    # Create frequency dictionary: { 'Hernandez': 1200, 'Garcia': 950 ... }
    freq_dict = dict(zip(state_subset['first_lastname'], state_subset['n']))

    # Create a high-res mask for the state boundary
    # This ensures words don't bleed into neighboring states
    minx, miny, maxx, maxy = state_geometry.bounds
    res = 1200 # Higher resolution = cleaner edges
    width = res
    height = int(res * ((maxy - miny) / (maxx - minx)))
    
    mask_img = Image.new('L', (width, height), 255)
    draw = ImageDraw.Draw(mask_img)
    
    # Handle both Polygons and MultiPolygons (for states with islands like Nueva Esparta)
    geoms = state_geometry.geoms if state_geometry.geom_type == 'MultiPolygon' else [state_geometry]
    for geom in geoms:
        x, y = geom.exterior.coords.xy
        coords = [(int((cx - minx) / (maxx - minx) * (width - 1)),
                   int((maxy - cy) / (maxy - miny) * (height - 1))) for cx, cy in zip(x, y)]
        draw.polygon(coords, fill=0)
    
    mask_array = np.array(mask_img)

    # Define color for this state
    # current_color = colors(idx)
    def state_color_func(*args, **kwargs):
        return current_color
    #    return tuple(int(c * 255) for c in current_color[:3])

    # 5. Generate WordCloud
    wc = WordCloud(
        background_color="rgba(255, 255, 255, 0)",
        mode="RGBA",
        mask=mask_array,
        color_func=state_color_func,
        max_words=250,
        prefer_horizontal=1, # Keep most readable, some vertical for "packing"
        font_path="Trujillo-Bold.ttf",         # You can point this to a .ttf file for better branding
        relative_scaling=0.5    # Font size relative to frequency
    ).generate_from_frequencies(freq_dict)

    # 6. Plot onto the map
    ax.imshow(wc, extent=[minx, maxx, miny, maxy], origin='upper', zorder=2)

# Optional: Add a subtle outline of the country for context
venezuela_map.boundary.plot(ax=ax, color="#ffffff", linewidth=0.5, zorder=1)

#plt.title("Mapa de Apellidos: Venezuela", fontsize=24, pad=20)
plt.savefig("figure_output3.png", dpi=400)
plt.show()