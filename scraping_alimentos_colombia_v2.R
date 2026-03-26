# =============================================================================
#  WEB SCRAPING EN R  |  Open Food Facts  |  Productos de Colombia
#  VERSIÓN CORREGIDA — fix en la función lista_a_texto (Paso 7)
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# PASO 1 │ Instalar paquetes (solo la PRIMERA vez)
# ─────────────────────────────────────────────────────────────────────────────
# install.packages(c(
#   "httr2", "jsonlite", "dplyr", "tidyr",
#   "purrr", "stringr", "readr", "writexl"
# ))

# ─────────────────────────────────────────────────────────────────────────────
# PASO 2 │ Cargar paquetes
# ─────────────────────────────────────────────────────────────────────────────
library(httr2)
library(jsonlite)
library(dplyr)
library(tidyr)
library(purrr)
library(stringr)
library(readr)
library(writexl)

cat("✔ Librerías cargadas\n")

# ─────────────────────────────────────────────────────────────────────────────
# PASO 3 │ Parámetros
# ─────────────────────────────────────────────────────────────────────────────
API_URL <- "https://world.openfoodfacts.org/api/v2/search"

CAMPOS <- paste(
  "code", "product_name", "brands", "quantity",
  "categories_tags", "countries_tags",
  "nutriscore_grade", "nova_group",
  "energy-kcal_100g", "fat_100g", "saturated-fat_100g",
  "carbohydrates_100g", "sugars_100g", "fiber_100g",
  "proteins_100g", "salt_100g", "sodium_100g",
  "allergens_tags", "labels_tags",
  "ingredients_text", "image_url",
  sep = ","
)

PROD_POR_PAGINA <- 100
TOTAL_PAGINAS   <- 3   # ← cambia según cuántos productos quieras

cat(sprintf("⚙  Configuración: %d páginas × %d = hasta %d productos\n",
            TOTAL_PAGINAS, PROD_POR_PAGINA, TOTAL_PAGINAS * PROD_POR_PAGINA))

# ─────────────────────────────────────────────────────────────────────────────
# PASO 4 │ Función de descarga
# ─────────────────────────────────────────────────────────────────────────────
descargar_pagina <- function(numero_pagina) {
  cat(sprintf("  → Descargando página %d...\n", numero_pagina))

  respuesta <- request(API_URL) |>
    req_url_query(
      countries_tags = "en:colombia",
      fields         = CAMPOS,
      page_size      = PROD_POR_PAGINA,
      page           = numero_pagina,
      sort_by        = "last_modified_t"
    ) |>
    req_headers(`User-Agent` = "ScriptR-Colombia/1.0 (ejercicio@ejemplo.com)") |>
    req_timeout(30) |>
    req_perform()

  contenido <- respuesta |>
    resp_body_string() |>
    fromJSON(flatten = TRUE)

  return(contenido$products)
}

# ─────────────────────────────────────────────────────────────────────────────
# PASO 5 │ Bucle de descarga
# ─────────────────────────────────────────────────────────────────────────────
cat("\n📡 Iniciando descarga...\n")

paginas <- list()

for (p in seq_len(TOTAL_PAGINAS)) {
  resultado <- tryCatch(
    expr  = descargar_pagina(p),
    error = function(e) {
      cat(sprintf("  ✗ Error en página %d: %s\n", p, conditionMessage(e)))
      NULL
    }
  )
  if (!is.null(resultado) && nrow(resultado) > 0) {
    paginas[[p]] <- resultado
    cat(sprintf("  ✔ Página %d: %d productos\n", p, nrow(resultado)))
  }
  if (p < TOTAL_PAGINAS) Sys.sleep(1.5)
}

datos_crudos <- bind_rows(paginas)
cat(sprintf("\n✔ Total descargado: %d filas\n", nrow(datos_crudos)))

# ─────────────────────────────────────────────────────────────────────────────
# PASO 6 │ Exploración rápida
# ─────────────────────────────────────────────────────────────────────────────
cat("\n🔍 Primeras columnas disponibles:\n")
print(names(datos_crudos))

# ─────────────────────────────────────────────────────────────────────────────
# PASO 7 │ Limpieza  ← AQUÍ ESTABA EL BUG, YA CORREGIDO
# ─────────────────────────────────────────────────────────────────────────────
cat("\n🧹 Limpiando datos...\n")

# ── CORRECCIÓN ────────────────────────────────────────────────────────────────
# El problema original: map_chr() exigía que cada celda de lista devolviera
# exactamente 1 valor. Pero columnas como categorias_tags contienen vectores
# de 8, 10 o más elementos por fila.
#
# Solución: usar safely() + collapse para manejar cualquier longitud,
# y reemplazar map_chr() por map_chr() con una función más robusta.
# ─────────────────────────────────────────────────────────────────────────────

lista_a_texto <- function(x) {
  # Acepta: NULL, NA, vector de cualquier longitud, lista anidada
  if (is.null(x))            return(NA_character_)
  if (length(x) == 0)        return(NA_character_)
  # Si es una lista, aplanarla primero
  if (is.list(x)) x <- unlist(x, use.names = FALSE)
  # Eliminar NAs internos y unir con " ; "
  x <- x[!is.na(x)]
  if (length(x) == 0)        return(NA_character_)
  paste(as.character(x), collapse = " ; ")
}

# Función segura para aplicar sobre columnas de lista con map_chr()
lista_a_texto_segura <- function(columna) {
  # columna es un vector de listas (list-column de dplyr)
  vapply(columna, lista_a_texto, character(1))
}

datos_limpios <- datos_crudos |>

  # 7.1 Seleccionar y renombrar columnas
  select(any_of(c(
    codigo_barras   = "code",
    nombre          = "product_name",
    marca           = "brands",
    cantidad        = "quantity",
    nutriscore      = "nutriscore_grade",
    nova            = "nova_group",
    kcal_100g       = "energy-kcal_100g",
    grasas_100g     = "fat_100g",
    grasas_sat_100g = "saturated-fat_100g",
    carbos_100g     = "carbohydrates_100g",
    azucares_100g   = "sugars_100g",
    fibra_100g      = "fiber_100g",
    proteinas_100g  = "proteins_100g",
    sal_100g        = "salt_100g",
    sodio_100g      = "sodium_100g",
    categorias      = "categories_tags",
    alergenos       = "allergens_tags",
    etiquetas       = "labels_tags",
    ingredientes    = "ingredients_text",
    foto_url        = "image_url"
  ))) |>

  # 7.2 Convertir list-columns a texto — versión robusta con vapply
  mutate(across(
    where(is.list),
    lista_a_texto_segura
  )) |>

  # 7.3 Limpiar texto
  mutate(
    nombre       = str_squish(nombre),
    marca        = str_squish(marca),
    cantidad     = str_squish(cantidad),
    ingredientes = str_squish(ingredientes),
    nombre       = str_to_sentence(nombre),
    categorias   = str_remove_all(categorias, "(en|es|fr|de|it|pt):"),
    alergenos    = str_remove_all(alergenos,  "(en|es|fr|de|it|pt):"),
    etiquetas    = str_remove_all(etiquetas,  "(en|es|fr|de|it|pt):"),
    nutriscore   = str_to_upper(nutriscore)
  ) |>

  # 7.4 Convertir numéricos
  mutate(across(
    c(kcal_100g, grasas_100g, grasas_sat_100g, carbos_100g,
      azucares_100g, fibra_100g, proteinas_100g, sal_100g, sodio_100g, nova),
    ~ suppressWarnings(as.numeric(.x))
  )) |>

  # 7.5 Etiqueta descriptiva NOVA
  mutate(
    nova_desc = case_when(
      nova == 1 ~ "Sin procesar",
      nova == 2 ~ "Ingrediente culinario",
      nova == 3 ~ "Procesado",
      nova == 4 ~ "Ultraprocesado",
      TRUE      ~ NA_character_
    )
  ) |>

  # 7.6 Filtrar filas vacías y duplicados
  filter(!is.na(nombre), str_length(nombre) > 1) |>
  distinct(codigo_barras, .keep_all = TRUE)

cat(sprintf("✔ Filas limpias: %d  |  Columnas: %d\n",
            nrow(datos_limpios), ncol(datos_limpios)))

# ─────────────────────────────────────────────────────────────────────────────
# PASO 8 │ Resumen exploratorio
# ─────────────────────────────────────────────────────────────────────────────
cat("\n📊 Distribución Nutri-Score:\n")
datos_limpios |>
  filter(!is.na(nutriscore)) |>
  count(nutriscore) |>
  arrange(nutriscore) |>
  print()

cat("\n📊 Distribución NOVA:\n")
datos_limpios |>
  filter(!is.na(nova)) |>
  count(nova, nova_desc) |>
  arrange(nova) |>
  print()

cat("\n📊 Top 10 marcas:\n")
datos_limpios |>
  filter(!is.na(marca), marca != "") |>
  count(marca, sort = TRUE) |>
  slice_head(n = 10) |>
  print()

# ─────────────────────────────────────────────────────────────────────────────
# PASO 9 │ Exportar CSV
# ─────────────────────────────────────────────────────────────────────────────
fecha_hoy   <- format(Sys.Date(), "%Y-%m-%d")
nombre_base <- paste0("alimentos_colombia_", fecha_hoy)
ruta_csv    <- paste0(nombre_base, ".csv")
ruta_xlsx   <- paste0(nombre_base, ".xlsx")

write_csv(datos_limpios, ruta_csv, na = "")
cat(sprintf("\n💾 CSV  → %s\n", ruta_csv))

# ─────────────────────────────────────────────────────────────────────────────
# PASO 10 │ Exportar Excel (4 hojas)
# ─────────────────────────────────────────────────────────────────────────────
resumen_nutriscore <- datos_limpios |>
  filter(!is.na(nutriscore)) |>
  group_by(nutriscore) |>
  summarise(
    n_productos       = n(),
    kcal_promedio     = round(mean(kcal_100g,      na.rm = TRUE), 1),
    azucar_promedio   = round(mean(azucares_100g,  na.rm = TRUE), 1),
    grasa_promedio    = round(mean(grasas_100g,    na.rm = TRUE), 1),
    proteina_promedio = round(mean(proteinas_100g, na.rm = TRUE), 1),
    .groups = "drop"
  ) |>
  mutate(descripcion = case_when(
    nutriscore == "A" ~ "Muy buena calidad nutricional",
    nutriscore == "B" ~ "Buena calidad nutricional",
    nutriscore == "C" ~ "Calidad media",
    nutriscore == "D" ~ "Calidad baja",
    nutriscore == "E" ~ "Calidad muy baja",
    TRUE              ~ "Sin clasificar"
  )) |>
  arrange(nutriscore)

resumen_nova <- datos_limpios |>
  filter(!is.na(nova)) |>
  group_by(nova, nova_desc) |>
  summarise(
    n_productos   = n(),
    kcal_promedio = round(mean(kcal_100g,     na.rm = TRUE), 1),
    azucar_prom   = round(mean(azucares_100g, na.rm = TRUE), 1),
    .groups = "drop"
  ) |>
  arrange(nova)

top_marcas <- datos_limpios |>
  filter(!is.na(marca), marca != "") |>
  group_by(marca) |>
  summarise(
    n_productos   = n(),
    kcal_promedio = round(mean(kcal_100g,     na.rm = TRUE), 1),
    azucar_prom   = round(mean(azucares_100g, na.rm = TRUE), 1),
    .groups = "drop"
  ) |>
  arrange(desc(n_productos)) |>
  slice_head(n = 30)

write_xlsx(
  list(
    "Todos los productos" = datos_limpios,
    "Por Nutri-Score"     = resumen_nutriscore,
    "Por NOVA"            = resumen_nova,
    "Top 30 marcas"       = top_marcas
  ),
  ruta_xlsx
)

cat(sprintf("💾 Excel → %s  (4 hojas)\n", ruta_xlsx))

# ─────────────────────────────────────────────────────────────────────────────
# PASO 11 │ Resultado final
# ─────────────────────────────────────────────────────────────────────────────
cat("\n", strrep("═", 50), "\n", sep = "")
cat("   ✅ ¡Proceso completado!\n")
cat(strrep("═", 50), "\n", sep = "")
cat(sprintf("  Productos : %d\n", nrow(datos_limpios)))
cat(sprintf("  CSV       : %s\n", ruta_csv))
cat(sprintf("  Excel     : %s\n", ruta_xlsx))
cat(strrep("═", 50), "\n\n", sep = "")

cat("Vista previa (5 primeros productos):\n")
datos_limpios |>
  select(nombre, marca, nutriscore, nova,
         kcal_100g, azucares_100g, proteinas_100g) |>
  slice_head(n = 5) |>
  print()
