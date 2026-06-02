# =================================================================
# SCRIPT 1: LIMPIEZA Y PROCESAMIENTO DE DATOS (ODS 8.7)
# =================================================================

library(readr)
library(dplyr)
library(tidyr)
library(lubridate)

# 1. Carga de datos crudos
ruta_cruda <- "C:/Users/Emmanuel/Documents/trata-personas-mexico-ods87/data/raw/Estatal-Víctimas-2015-2025_ene2026.csv"
df_crudo <- read_csv(ruta_cruda, locale = locale(encoding = "Latin1"))

# 2. Conversión de estructuras y Pivotaje
df_long <- df_crudo %>%
  mutate(
    Año = as.integer(Año),
    Clave_Ent = as.integer(Clave_Ent),
    across(Enero:Diciembre, as.integer)
  ) %>%
  pivot_longer(
    cols = c("Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", 
             "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"),
    names_to = "Mes",
    values_to = "Numero Victimas" # Cambiado a 'Numero Victimas' para emparejar tu Power BI
  )

# 3. Normalización, Filtrado y Construcción de Fechas
df_limpio <- df_long %>%
  mutate(
    Delito_Norm = toupper(`Tipo de delito`),
    Sexo_Norm   = toupper(Sexo),
    Mes_Norm    = toupper(Mes) 
  ) %>%
  filter(
    Delito_Norm == "TRATA DE PERSONAS",
    Sexo_Norm %in% c("MUJER", "HOMBRE")
  ) %>%
  mutate(
    # Cambiado a 'MesNum' para emparejar con la captura de tu tabla
    MesNum = case_when(
      Mes_Norm == "ENERO"      ~ 1,  Mes_Norm == "FEBRERO"   ~ 2,
      Mes_Norm == "MARZO"      ~ 3,  Mes_Norm == "ABRIL"     ~ 4,
      Mes_Norm == "MAYO"       ~ 5,  Mes_Norm == "JUNIO"     ~ 6,
      Mes_Norm == "JULIO"      ~ 7,  Mes_Norm == "AGOSTO"    ~ 8,
      Mes_Norm == "SEPTIEMBRE" ~ 9,  Mes_Norm == "OCTUBRE"   ~ 10,
      Mes_Norm == "NOVIEMBRE"  ~ 11, Mes_Norm == "DICIEMBRE" ~ 12
    ),
    FechaHecho = make_date(year = Año, month = MesNum, day = 1)
  ) %>%
  # 🛠️ CREACIÓN AUTOMÁTICA DEL CÓDIGO JSON GEOGRÁFICO
  mutate(
    Entidad_Clean = toupper(gsub(" ", "", Entidad)), # Elimina espacios intermedios
    Codigo_Estado_JSON = paste0("MX", substr(Entidad_Clean, 1, 3)),
    # Ajustes manuales específicos para estados compuestos
    Codigo_Estado_JSON = case_when(
      Entidad_Clean == "CIUDADDEMEXICO" ~ "MXCMX",
      Entidad_Clean == "NUEVOLEON"      ~ "MXNLE",
      TRUE ~ Codigo_Estado_JSON
    )
  ) %>%
  # Selección y ordenamiento estricto respetando la estructura completa de tus imágenes
  select(
    Año, Clave_Ent, Entidad, `Bien jurídico afectado`, `Tipo de delito`, 
    `Subtipo de delito`, Modalidad, Sexo, `Rango de edad`, Mes, 
    `Numero Victimas`, FechaHecho, MesNum, Codigo_Estado_JSON
  ) %>%
  arrange(FechaHecho)

# 4. ENTREGABLE 1: Crear agrupación nacional resumida únicamente para la Serie de Tiempo
df_serie_tiempo <- df_limpio %>%
  group_by(FechaHecho) %>%
  summarise(Total_Victimas = sum(`Numero Victimas`, na.rm = TRUE)) %>%
  ungroup()


# =================================================================
#  EXPORTACIÓN (CON TUS RUTAS ACTIVAS)
# =================================================================

# Rutas de salida para tus carpetas locales
ruta_completo     <- "C:/Users/Emmanuel/Documents/trata-personas-mexico-ods87/data/processed/dataset_completo_limpio.csv"
ruta_serie_tiempo <- "C:/Users/Emmanuel/Documents/trata-personas-mexico-ods87/data/processed/dataset_serie_tiempo.csv"

# Escribir ambos archivos CSV
write_csv(df_limpio, ruta_completo)
write_csv(df_serie_tiempo, ruta_serie_tiempo)

print("¡Proceso completado con éxito!")
print(paste("1. Dataset Completo (con Entidades y Género) guardado en:", ruta_completo))
print(paste("2. Dataset de Serie de Tiempo (Resumido) guardado en:", ruta_serie_tiempo))
