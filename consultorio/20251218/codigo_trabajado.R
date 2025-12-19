### Contexto:
# Gerardo nos presentó datasets, y un script que llegaba a un punto donde utilizamos solo el
# dataset `cober.AIOCrop`.
# No doy más información de los datasets ni el script, porque pertenecen a Gerardo.
# `cober.AIOCrop`: dada una región geográfica, presentaba para diversos años, la cobertura
# detectada, codificada del 1 al 7 (como veremos más adelante).
# Colaborativamente, entre los asistentes, llegamos a las ideas de:
# 1. Hacer un gráfico con todos los años -lado a lado- (para propósitos de publicación en revista).
# 2. Hacer un gráfico con animación, en el cual se viera la evolución de la cobertura.
# 3. Compartir contenido sobre como mejorar la animación mediante librerías especializadas en
#    mapas.

class(cober.AIOCrop)
# [1] "RasterBrick"
# attr(,"package")
# [1] "raster"

# Convertimos la estructura en data.frame.
cober_AIOCrop_df <- na.omit(as.data.frame(cober.AIOCrop, xy = TRUE))
dim(cober_AIOCrop_df)
# [1] 182021     15
head(cober_AIOCrop_df)
#         x        y c2003 c2009 c2013 c2015 c2016 c2017 c2018 c2019 c2020 c2022 c2023 c2024 c2025
# -90.33202 15.41118     3     3     1     1     1     1     1     1     3     1     1     1     1
# -90.33176 15.41118     3     3     3     3     7     3     3     3     3     1     1     3     1
# -90.33149 15.41118     3     3     3     3     3     3     3     3     3     3     3     3     5
# -90.33122 15.41118     3     3     3     3     3     3     3     5     3     3     3     5     5
# -90.33095 15.41118     3     3     3     3     3     3     3     3     3     3     5     5     5
# -90.33068 15.41118     3     3     3     3     3     3     3     3     3     3     3     5     3

# La mutamos a formato longer.
cober_AIOCrop_df_long <- tidyr::pivot_longer(
  cober_AIOCrop_df,
  c(-x, -y),
  names_to = "year",
  values_to = "Cobertura"
) |>
  mutate(
    year = as.integer(gsub("\\D", "", year)),
    Cobertura = factor(
      Cobertura,
      levels = 1:7,
      c("Bosque", "Cultivos", "Suelo_descubierto", "Sarán", "Urbano", "Guamil", "Agua")
    )
  )

# Damos valores random, para no filtrar el dataset de Gerardo.
cober_AIOCrop_df_long$Cobertura <- sample(cober_AIOCrop_df_long$Cobertura)

# Creamos el gráfico base.
base_plot <- ggplot(cober_AIOCrop_df_long) +
  geom_raster(aes(x = x, y = y, fill = Cobertura)) +
  scale_fill_manual(values = terrain.colors(7), name = "Cobertura") +
  coord_equal() +
  theme_void() +
  theme(legend.position = "bottom")

# 1. Graficamos todos los años juntos.
base_plot + facet_wrap(year ~ .)

# 2. Creamos la animación año a año (toma un buen tiempo en renderizar).
base_plot +
  labs(title = "Año {closest_state}") +
  # Probar alternativas de `transition_*`.
  gganimate::transition_states(
    year,
    transition_length = 0,
    state_length = 1
  )
