# =================================================================
# SCRIPT 2: ANÁLISIS AVANZADO DE SERIE DE TIEMPO Y FORECASTING
# =================================================================

library(readr)
library(dplyr)
library(forecast)
library(ggplot2)

# 1. Cargar el dataset optimizado para la Serie de Tiempo (ODS 8.7)
ruta_procesada <- "C:/Users/Emmanuel/Documents/trata-personas-mexico-ods87/data/processed/dataset_serie_tiempo.csv"
datos_mensuales <- read_csv(ruta_procesada)

# 2. Estructurar el objeto de Serie de Tiempo (TS)
serie_tiempo <- ts(datos_mensuales$Total_Victimas, start = c(2015, 1), frequency = 12)

# =================================================================
#  ESTUDIO COMPLETO Y DESCOMPOSICIÓN DE LA SERIE
# =================================================================

# 2.1. Descomposición STL (Seasonal and Trend decomposition using Loess)
# Separa de manera matemática: Tendencia limpia, Estacionalidad y Residuo Irregular
descomposicion_stl <- stl(serie_tiempo, s.window = "periodic")

# Visualizar la descomposición en el Plots Viewer
plot(descomposicion_stl, main = "Descomposición STL: Tendencia, Estacionalidad y Residuo")

# 2.2. Análisis Estadístico de Autocorrelación (ACF y PACF)
Acf(serie_tiempo, main = "Gráfico de Autocorrelación (ACF) - Datos Históricos")

# =================================================================
#  MODELADO PREDICTIVO CON HOLT-WINTERS (ETS)
# =================================================================

# 3.1. Ajustar el modelo estacional aditivo amortiguado
modelo_ets <- ets(serie_tiempo, model = "AAA")

# 3.2. Proyectar 24 meses hacia el futuro (Todo 2026 y 2027)
proyeccion <- forecast(modelo_ets, h = 24, level = 95)

# =================================================================
#  CONSTRUCCIÓN Y ANCLAJE VISUAL DE LA GRÁFICA DE PROYECCIÓN
# =================================================================

ultima_fecha_hist <- tail(datos_mensuales$FechaHecho, 1)
ultimo_valor_hist <- tail(datos_mensuales$Total_Victimas, 1)
fechas_futuras     <- seq(ultima_fecha_hist, by = "month", length.out = 25)

df_pronostico <- data.frame(
  Fecha    = fechas_futuras,
  Victimas = c(ultimo_valor_hist, as.numeric(proyeccion$mean)),
  Lower    = c(ultimo_valor_hist, as.numeric(proyeccion$lower)),
  Upper    = c(ultimo_valor_hist, as.numeric(proyeccion$upper))
)

df_historico <- data.frame(Fecha = datos_mensuales$FechaHecho, Victimas = datos_mensuales$Total_Victimas)

# Gráfico de Proyección con Intervalos de Confianza y Anclaje Visual
grafico_forecast <- ggplot() +
  geom_ribbon(data = df_pronostico, aes(x = Fecha, ymin = Lower, ymax = Upper), fill = "#E19DA1", alpha = 0.3) +
  geom_line(data = df_historico, aes(x = Fecha, y = Victimas), color = "#6B2328", size = 0.8) +
  geom_line(data = df_pronostico, aes(x = Fecha, y = Victimas), color = "#6B2328", linetype = "dashed", size = 0.8) +
  scale_x_date(limits = c(as.Date("2015-01-01"), as.Date("2027-12-31")), date_breaks = "2 years", date_labels = "%Y") +
  labs(
    title = "Predicción de Víctimas de Trata de Personas (2015 - 2027)",
    subtitle = "Modelo Avanzado de Suavizado Exponencial de Holt-Winters (ETS)",
    x = "Año",
    y = "Número de Víctimas"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", color = "#6B2328", size = 12, hjust = 0.5),
    plot.subtitle = element_text(size = 9, hjust = 0.5, face = "italic"),
    axis.title = element_text(size = 10),
    axis.text = element_text(size = 8),
    panel.grid.major = element_line(color = "#E19DA1", size = 0.15, linetype = "dashed"),
    panel.grid.minor = element_blank()
  )

print(grafico_forecast)

# =================================================================
#  EVALUACIÓN DE CALIDAD ESTADÍSTICA (MÉTRICAS Y RESIDUOS)
# =================================================================

print("--- INDICADORES DE PRECISIÓN MATEMÁTICA ---")
summary(modelo_ets)

print("--- ANÁLISIS DE RESIDUOS (RUIDO BLANCO) ---")
# Genera el panel final de tres gráficos para evaluar la independencia de los errores
checkresiduals(modelo_ets)
