# Consultorio Abierto de R | Sesión #1

**Fecha**: 18 de diciembre de 2025
**Duración**: ~45 minutos
**Hosts**: Juan Cruz Rodriguez (Cancu) y Pablo Tiscornia

---

## Resumen

Primera sesión del Consultorio Abierto de R, un espacio quincenal para resolver dudas de programación en R en comunidad. En este encuentro trabajamos sobre el caso de **Gerardo Molina**, quien buscaba mejorar la visualización de datos geoespaciales de uso de suelo.

---

## Caso de la sesión: Visualización de datos geoespaciales

### El problema

Gerardo trabaja con series multitemporales de imágenes satelitales (archivos TIF) para analizar cambios en el uso del suelo. Su visualización actual mostraba las coberturas de suelo demasiado saturadas y difíciles de interpretar.

### Soluciones propuestas

| Enfoque | Descripción |
|---------|-------------|
| **Animación** | Mostrar la evolución del foliaje año a año con transiciones |
| **Grilla de imágenes** | Comparar múltiples años lado a lado |
| **Mapas interactivos** | Usar capas para explorar diferentes años |
| **Barra de contraste** | Comparar dos años específicos con slider |

---

## Paquetes mencionados

| Paquete | Uso |
|---------|-----|
| [`pacman`](https://cran.r-project.org/package=pacman) | Gestión de paquetes |
| [`box`](https://klmr.me/box/) | Modularización de código |
| [`ggplot2`](https://ggplot2.tidyverse.org/) + `theme_void()` | Limpiar el fondo de mapas |
| [`gganimate`](https://gganimate.com/) | Animaciones en ggplot2 |
| [`leaflet`](https://rstudio.github.io/leaflet/) | Mapas interactivos con capas |
| [`mapgl`](https://walker-data.com/mapgl/) | Mapas interactivos con barra de contraste (wrapper de Mapbox) |
| [`mapview`](https://r-spatial.github.io/mapview/) | Mapas animados |

---

## Tips compartidos

- **Ordenar librerías alfabéticamente** para mejorar la legibilidad del código
- **Mover la consola de RStudio a la derecha** para mejor organización del espacio de trabajo
- **Usar `theme_void()`** para limpiar el fondo en visualizaciones de mapas
- **Consultar IA desde RStudio** sin salir del IDE (usando paquetes como `myownrobs`)

---

## Momento IA

Cancu demostró cómo consultar asistentes de IA directamente desde RStudio usando [`myownrobs`](https://github.com/MyOwnRobs/myownrobs), un paquete desarrollado por él mismo que fue presentado en [LatinR](https://latinr.org/). Este paquete permite interactuar con modelos de lenguaje sin salir del IDE.

La IA generó código funcional pero excesivamente complejo para la tarea.

**Aprendizaje**: El conocimiento del programador permite identificar soluciones más simples. Las herramientas de IA son útiles, pero el criterio humano sigue siendo fundamental.

---

## Aportes de la comunidad

- **Gabriela**: Sugirió que para publicaciones, una opción efectiva es mostrar las imágenes lado a lado

---

## Participantes

Tuvimos asistentes de diversos países: Guatemala, México y Argentina.

---

## Próximos pasos

- [ ] Cancu enviará a Gerardo la solución con mapview animado y grilla de imágenes
- [ ] Pablo armará un canal de comunicación (Discord o Slack) para continuar la interacción
- [ ] Próxima sesión programada para enero 2026

---

## Recursos

- **Repositorio**: [github.com/Estacion-R/estacion-r-streaming](https://github.com/Estacion-R/estacion-r-streaming)
- **Documento de recursos compartidos**: *(próximamente)*
- **Grabación**: *(próximamente)*

---

## Contacto

- Estación R: [@Estacion_R](https://x.com/estacion_erre)
- **Pablo Tiscornia**
- **Juan Cruz Rodriguez (Cancu)** - [@CancuCS](https://x.com/CancuCS)

---

*¿Tenés una duda de R que quieras resolver en vivo? ¡Sumate al próximo consultorio!*
