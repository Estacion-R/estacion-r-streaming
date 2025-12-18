# AGENT.md - Guía para Asistentes de IA

## Descripción del Proyecto

**Consultorio Abierto de R** es una iniciativa de la comunidad **Estación R**, impulsada por Pablo Tiscornia y Juan Cruz Rodriguez (Cancu). Es un espacio comunitario, gratuito y abierto para la comunidad hispanohablante de R.

### Concepto Principal

> "Una parada técnica para resolver tu código, en comunidad."

El Consultorio es un espacio donde nos juntamos 45 minutos en vivo para resolver dudas reales de R. Sin filtro y con código en pantalla. El objetivo es que los participantes puedan ver, en tiempo real, cómo alguien diagnostica un problema: piensa, se pregunta, aísla el error y lo resuelve.

## Formato de las Sesiones

- **Duración**: 30-45 minutos
- **Frecuencia**: Quincenal (cada dos semanas)
- **Modalidad**: En vivo
- **Acceso**: Libre y gratuito
- **Idioma**: Español
- **Requisitos**: Ninguno. Solo curiosidad y ganas de aprender.

## Formas de Participar

1. **Traer un caso**: Completar el formulario con una duda para que sea resuelta en vivo
2. **Asistir como oyente**: Sumarse para ver cómo se programa profesionalmente

## Estructura del Repositorio

```
estacion-r-streaming/
├── README.md           # Descripción principal del proyecto
├── AGENT.md            # Este archivo (guía para asistentes de IA)
├── LICENSE             # Licencia del proyecto
└── sesiones/           # Documentación de cada sesión
    └── sesion_1.md     # Notas de la sesión 1
```

## Documentación de Sesiones

Cada sesión se documenta con:
- Link al repositorio
- Link al documento de recursos compartidos
- Notas del encuentro (resumen, detalles, pasos siguientes)
- Grabaciones cuando estén disponibles

### Sesión #1 (18 dic 2025)

**Tema principal**: Visualización de datos geoespaciales de uso de suelo en R

**Caso resuelto**: Gerardo Molina buscaba mejorar la visualización de series multitemporales de imágenes satelitales (archivos TIF) que mostraban coberturas de suelo saturadas.

**Soluciones propuestas**:
- Animaciones para mostrar evolución del foliaje
- Grillas de imágenes para comparar años
- Paquetes sugeridos: `theme_void`, `leaflet`, `mapgl` (wrapper de Mapbox)
- Función `mapview` para mapas animados

**Participantes de diversos países**: Guatemala, México, Argentina

## Comunidad y Valores

- **Espacio 100% abierto**: Para interacción e intercambio de conocimientos
- **Informal**: Las personas acuden con dudas y entre todos se intenta responder
- **Multidisciplinario**: R es usado en diversas disciplinas
- **Colaborativo**: Se comparten recursos, links y experiencias
- **Reglas básicas**: Sentido común y respeto

## Equipo

- **Pablo Tiscornia** - Co-organizador
- **Juan Cruz Rodriguez (Cancu)** - [@CancuCS](https://x.com/CancuCS) - Líder del proyecto

## Canales de Comunicación

- **Repositorio GitHub**: [Estacion-R/estacion-r-streaming](https://github.com/Estacion-R/estacion-r-streaming)
- **Canal de chat**: En desarrollo (Discord o Slack)

## Contexto para Asistentes de IA

Cuando trabajes con este proyecto:

1. **Es un proyecto comunitario educativo**: El foco está en resolver dudas reales de programación en R de forma colaborativa

2. **Audiencia hispanohablante**: Todo el contenido está en español

3. **Diversidad de temas**: Los casos pueden ser de cualquier área donde se use R (estadística, visualización, datos geoespaciales, ciencia de datos, etc.)

4. **Documentación de sesiones**: Cada sesión en `sesiones/` sigue un formato similar con notas, resúmenes y recursos

5. **Tono informal y accesible**: El proyecto busca ser inclusivo para todos los niveles de R

6. **Código abierto y compartido**: Los scripts y soluciones discutidas se comparten abiertamente

## Cómo Ayudar

Si se te pide asistir con este proyecto, podrías:

- Ayudar a documentar sesiones pasadas
- Sugerir soluciones a problemas de R discutidos
- Mejorar la organización del repositorio
- Crear recursos educativos relacionados con los temas tratados
- Ayudar a preparar material para futuras sesiones
