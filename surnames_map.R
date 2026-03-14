library(sf)
library(tidyverse)
library(ggplot2)
library(ggwordcloud)  # install.packages("ggwordcloud")

# ── 1. Load shapefile ──────────────────────────────────────────────────────────
country_sf <- st_read("Estados_Venezuela.shp") |>
  sf::st_as_sf()

# ── 1b. ID crosswalk ───────────────────────────────────────────────────────────
id_crosswalk <- tibble::tribble(
  ~state_id, ~state_name,        ~shp_state_id,
  1,  "DTTO. CAPITAL",    0,
  2,  "EDO. ANZOATEGUI",  2,
  3,  "EDO. APURE",       3,
  4,  "EDO. ARAGUA",      4,
  5,  "EDO. BARINAS",     5,
  6,  "EDO. BOLIVAR",     6,
  7,  "EDO. CARABOBO",    7,
  8,  "EDO. COJEDES",     8,
  9,  "EDO. FALCON",      10,
  10, "EDO. GUARICO",     11,
  11, "EDO. LARA",        12,
  12, "EDO. MERIDA",      13,
  13, "EDO. MIRANDA",     14,
  14, "EDO. MONAGAS",     15,
  15, "EDO.NVA.ESPARTA",  16,
  16, "EDO. PORTUGUESA",  17,
  17, "EDO. SUCRE",       18,
  18, "EDO. TACHIRA",     19,
  19, "EDO. TRUJILLO",    20,
  20, "EDO. YARACUY",     22,
  21, "EDO. ZULIA",       23,
  22, "EDO. AMAZONAS",    1,
  23, "EDO. DELTA AMAC",  9,
  24, "EDO. LA GUAIRA",   21
)

# Join crosswalk to shapefile cleanly
country_sf <- st_read("Estados_Venezuela.shp") |>
  sf::st_as_sf() |>
  left_join(id_crosswalk, by = c("ID" = "shp_state_id"))

# ── 2. Assign a distinct colour per state ─────────────────────────────────────
palette_base <- c(
  "#E63946","#457B9D","#2A9D8F","#E9C46A","#F4A261",
  "#264653","#6A4C93","#1982C4","#8AC926","#FF595E",
  "#6A994E","#BC4749","#A7C957","#386641","#C77DFF",
  "#FF9F1C","#F72585","#4CC9F0","#7B2D8B","#06D6A0",
  "#FF6B6B","#FFE66D","#118AB2","#073B4C"
)
state_ids    <- sort(unique(id_crosswalk$state_id))
state_colors <- setNames(rep_len(palette_base, length(state_ids)), state_ids)

# ── 3. Prepare label data ──────────────────────────────────────────────────────
# Keep top N surnames per state to avoid overcrowding
TOP_N <- 15

lastname_state_counts <- lastname_state_counts |>
  mutate(state_id = as.integer(state_id))

df <- lastname_state_counts |>
  filter(state_id != 99) |>
  group_by(state_id) |>
  arrange(desc(n), .by_group = TRUE) |>
  slice_head(n = TOP_N) |>
  mutate(
    rank     = row_number(),
    color    = state_colors[as.character(state_id)],
    # Scale font size within state: top name = 1, others proportional
    size_rel = n / max(n)
  ) |>
  ungroup()

# ── 4. Compute per-state bounding boxes & centroids ───────────────────────────
state_meta <- country_sf |>
  filter(!is.na(state_id)) |>
  mutate(
    area_km2  = as.numeric(st_area(geometry)) / 1e6,
    centroid  = st_centroid(geometry),
    cx        = st_coordinates(centroid)[, 1],
    cy        = st_coordinates(centroid)[, 2],
    bbox      = map(geometry, st_bbox),
    xmin      = map_dbl(bbox, "xmin"),
    xmax      = map_dbl(bbox, "xmax"),
    ymin      = map_dbl(bbox, "ymin"),
    ymax      = map_dbl(bbox, "ymax"),
    x_range   = xmax - xmin,
    y_range   = ymax - ymin
  ) |>
  st_drop_geometry() |>
  select(state_id, cx, cy, xmin, xmax, ymin, ymax, x_range, y_range, area_km2)

df <- df |> left_join(state_meta, by = "state_id")

# ── 5. Scale font sizes by state area ─────────────────────────────────────────
# Larger states get bigger text so names fill the polygon
area_range <- range(state_meta$area_km2)

df <- df |>
  mutate(
    # max font size for this state (pt units for ggwordcloud)
    size_max  = scales::rescale(sqrt(area_km2),
                                to   = c(2, 9),
                                from = sqrt(area_range)),
    fontsize  = size_max * (0.4 + 0.6 * size_rel)
  )

# ── 6. Place word clouds using ggwordcloud ────────────────────────────────────
# ggwordcloud places words around (x=0, y=0) within a mask.
# We use geom_text_wordcloud with x/y set to centroid and
# the eccentricity / grid size controlled per state.

# For a truly clipped word cloud we generate each state's cloud separately
# as an annotation, using the state polygon as a mask.

# Split into per-state data frames
df_list <- df |> group_by(state_id) |> group_split()

# Base map layer
p <- ggplot() +
  geom_sf(data = country_sf, fill = "grey96", color = "grey60", linewidth = 0.3)

# Add word cloud layer per state
for (d in df_list) {
  sid   <- unique(d$state_id)
  meta  <- state_meta |> filter(state_id == sid)
  if (nrow(meta) == 0) next
  
  p <- p +
    geom_text_wordcloud(
      data         = d,
      aes(label    = toupper(first_lastname),
          size     = fontsize,
          color    = color,
          fontface = ifelse(rank == 1, "bold", "plain")),
      x            = meta$cx,
      y            = meta$cy,
      # eccentricity controls cloud shape (1 = circle, <1 = wider ellipse)
      eccentricity = meta$x_range / meta$y_range,
      # rm_outside removes words that don't fit — keeps cloud tidy
      rm_outside   = TRUE,
      show.legend  = FALSE,
      seed         = 42
    )
}

p <- p +
  scale_size_identity() +
  scale_color_identity() +
  coord_sf(expand = FALSE) +
  theme_void() +
  theme(
    plot.background = element_rect(fill = "white", color = NA),
    plot.margin     = margin(10, 10, 10, 10),
    plot.title      = element_text(hjust = 0.5, size = 16, face = "bold",
                                   margin = margin(b = 6)),
    plot.caption    = element_text(hjust = 1, size = 8, color = "grey50")
  ) +
  labs(
    title   = "Most Common Last Names by State in Venezuela",
    caption = "Source: your data"
  )

print(p)

# ── 7. Export ─────────────────────────────────────────────────────────────────
ggsave("venezuela_lastname_map.png", p,
       width = 14, height = 10, dpi = 300, bg = "white")