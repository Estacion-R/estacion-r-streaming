# Consultorio Abierto de R #2 - LLMs en R con {ellmer}

📅 **Fecha:** 8 de enero de 2026

## Contenido

En esta sesión, [Cancu](https://x.com/CancuCS) presentó una demo sobre cómo integrar **Grandes Modelos de Lenguaje (LLMs)** en flujos de trabajo de R usando el paquete `{ellmer}`.

## Archivos

| Archivo | Descripción |
|---------|-------------|
| `demo_llm.R` | Script completo de la demo con ejemplos de tool calling |

## Temas cubiertos

- ✅ Inicialización de clientes para OpenAI y Google Gemini
- ✅ Registro de herramientas (tool calling) con funciones de R
- ✅ Ejemplo: darle acceso a la hora actual (`Sys.time`)
- ✅ Ejemplo: consultar descargas de R con `{cranlogs}`
- ✅ Interfaces interactivas: `live_console()` y `live_browser()`
- ✅ Control de costos con `$get_cost()`

## Paquetes utilizados

- [`ellmer`](https://ellmer.tidyverse.org/) - Interfaz unificada para LLMs en R
- [`cranlogs`](https://r-hub.github.io/cranlogs/) - Estadísticas de descargas de CRAN

## Configuración previa

Para ejecutar el script necesitás:

1. Instalar los paquetes:
```r
install.packages("ellmer")
install.packages("cranlogs")
```

2. Configurar las API keys en tu archivo `.Renviron`:
```
GOOGLE_API_KEY=tu_clave_aquí
OPENAI_API_KEY=tu_clave_aquí
```

## Recursos

- 📝 [Artículo en el blog de Estación R](https://estacion-r.com/blog)
- 📚 [Documentación oficial de {ellmer}](https://ellmer.tidyverse.org/)

---

*[Estación R](https://estacion-r.com/) - Escuela de Datos*
