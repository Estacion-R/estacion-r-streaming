### Demo LLMs en R

# Carga la librería 'ellmer', la interfaz moderna de Posit para LLMs.
library("ellmer")

# Se inicializa un cliente para OpenAI.
chatgpt <- chat_openai(model = "gpt-4.1")

# Se inicializa un cliente para Google Gemini.
# 'seed' fija la semilla para "intentar" que las respuestas sean reproducibles.
gemini <- chat_google_gemini(
  model = "gemini-2.5-flash",
  params = params(seed = 24061989)
)

# Registro de Herramientas (Tool Calling)
# Aquí ocurre la magia: le enseñamos a Gemini a usar funciones de R (que corren en mi maquina).

# Herramienta 1: Saber la hora.
# La IA no tiene reloj interno; le damos acceso a la función Sys.time de R.
gemini$register_tool(tool(
  Sys.time,
  name = "now",
  description = "Devuelve el dia y hora actuales."
))

# Definición de una función auxiliar para obtener el numero de descargas de R.
r_downloads_per_day <- function(from, to) {
  cranlogs::cran_downloads("R", from = from, to = to)
}

# Herramienta 2: Datos de descargas.
# Le damos a la IA capacidad de consultar estadísticas reales de paquetes.
# Se define explícitamente qué argumentos necesita (from, to) y sus formatos.
gemini$register_tool(tool(
  r_downloads_per_day,
  name = "r_download_per_day",
  description = "Devuelve el numero de veces que se descargo R, dia a dia.",
  arguments = list(
    from = type_string("Start date, en formato yyyy-mm-dd"),
    to = type_string("End date, en formato yyyy-mm-dd")
  )
))

# Muestra las herramientas que el agente 'gemini' tiene disponibles ahora.
gemini$get_tools()

# Interacción (El Agente en acción)
# Pregunta simple: Solo requiere la herramienta "now".
gemini$chat("Que dia es hoy?")

# Pregunta compleja: La IA debe primero usar la herramienta "now" para saber la fecha de hoy,
# calcular el "mes pasado", y luego llamar a "r_download_per_day" con las fechas correctas.
gemini$chat("Cuantas veces se descargo R dia a dia durante el mes pasado?")

# Interfaces Interactivas
# Abre una interfaz de chat en la consola de RStudio.
live_console(gemini)
# Abre una interfaz gráfica web (estilo Shiny) para charlar con el agente.
live_browser(gemini)

# Control de Costos
# Muestra cuánto dinero/tokens se han consumido en la sesión.
gemini$get_cost()
