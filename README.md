# 🛒 Análisis de Precios — Canasta Básica Colombia 2025

> ¿Qué alimentos han bajado de precio y cuáles seguirán subiendo?  
> Web scraping + SQL + análisis exploratorio con R

![R](https://img.shields.io/badge/Lenguaje-R%204.1%2B-276DC3?style=flat&logo=r)
![License](https://img.shields.io/badge/Licencia-MIT-green?style=flat)
![Fuente](https://img.shields.io/badge/Fuente-Open%20Food%20Facts%20%7C%20DANE-orange?style=flat)
![Estado](https://img.shields.io/badge/Estado-Completo-brightgreen?style=flat)

---

## 📌 Descripción

Este proyecto extrae, limpia y analiza datos de precios de alimentos de la canasta básica colombiana combinando dos fuentes de datos abiertas:

- **API SIPSA — datos.gov.co** (precios mayoristas agropecuarios del DANE)
- **IPC DANE** (variaciones anuales por subclase alimentaria 2022–2025)

Los datos se integran en una base de datos **SQLite**, se analizan con `tidyverse` y se visualizan con `ggplot2`. Los resultados se exportan en **CSV** y **Excel** con múltiples hojas temáticas.

Desarrollado como proyecto de la **Unidad 2 — Lenguajes de Programación en Ciencia de Datos**.

---

## 🎯 Pregunta de investigación

> *¿Qué alimentos de la canasta básica colombiana han bajado de precio en 2025 y cuáles continuarán subiendo en 2026, considerando factores climáticos, geopolíticos, de oferta estacional y tensiones sociales?*

---

## 📊 Resultados principales

| Alimento | Variación 2025 | Causa | Proyección 2026 |
|---|---|---|---|
| Papa | −24,6% | Cosecha récord + importaciones Ecuador | ⬆ Rebotará |
| Tomate | −15,9% | Cosecha simultánea varias regiones | ⬆ Rebotará |
| Arroz | −6,7% | Sobreoferta mundial + India | ↔ Estable |
| Café | +52,1% | Clima Brasil/Vietnam + aranceles Trump + EUDR | ⚠ Volátil |
| Carne de res | +9,6% | Costos transporte + exportaciones | ⬆ Sigue subiendo |
| Leguminosas | +6,8% | Importaciones + dólar alto | ⬆ Presión alcista |

---

## 🗂️ Estructura del repositorio

```
📁 canasta-basica-colombia/
│
├── 📄 canasta_basica_colombia_precios.R   ← Script principal
│
├── 📁 outputs/
│   ├── analisis_canasta_colombia_FECHA.csv    ← Datos exportados
│   ├── analisis_canasta_colombia_FECHA.xlsx   ← Excel (6 hojas)
│   ├── canasta_basica_colombia.sqlite         ← Base de datos SQL
│   ├── grafico1_variacion_2025.png            ← Variación por alimento
│   ├── grafico2_series_tiempo.png             ← Evolución 2022–2025
│   ├── grafico3_proyeccion_2026.png           ← Real 2025 vs proyección
│   └── grafico4_clasificacion.png             ← Distribución categorías
│
└── 📄 README.md
```

---

## 🔧 Tecnologías y paquetes

| Paquete | Uso |
|---|---|
| `httr2` | Web scraping — peticiones HTTP a la API SODA |
| `jsonlite` | Parseo de respuestas JSON |
| `dplyr` | Manipulación y limpieza de data frames |
| `tidyr` | Pivot y reestructuración de datos |
| `purrr` | Iteración robusta sobre list-columns |
| `stringr` | Limpieza de cadenas de texto |
| `lubridate` | Manejo de fechas |
| `ggplot2` | Visualizaciones |
| `DBI` + `RSQLite` | Base de datos SQLite y consultas SQL |
| `readr` | Exportación CSV |
| `writexl` | Exportación Excel (.xlsx) |

---

## ⚙️ Instalación y uso

### 1. Requisitos previos

- R 4.1 o superior → [descargar R](https://cran.r-project.org)
- RStudio (recomendado) → [descargar RStudio](https://posit.co/download/rstudio-desktop)
- Conexión a internet (para el web scraping)

### 2. Instalar paquetes

Abre R o RStudio y ejecuta:

```r
install.packages(c(
  "httr2", "jsonlite", "dplyr", "tidyr",
  "purrr", "stringr", "lubridate", "ggplot2",
  "DBI", "RSQLite", "readr", "writexl"
))
```

### 3. Ejecutar el script

```r
# En RStudio: abre el archivo y presiona Ctrl + Alt + R
# O desde la consola:
source("canasta_basica_colombia_precios.R")
```

### 4. Ajustar cantidad de datos (opcional)

Dentro del script, en el **Paso 3**, puedes cambiar cuántas páginas descarga:

```r
TOTAL_PAGINAS <- 3   # 1 página = 1000 registros (~10 seg por página)
```

---

## 📁 Archivos generados

Al ejecutar el script se crean automáticamente:

**`analisis_canasta_colombia_FECHA.xlsx`** con 6 hojas:
1. `IPC_Clasificacion` — todos los alimentos con variaciones y clasificación
2. `Alimentos_que_bajan` — solo alimentos con var_2025 < 0
3. `Alimentos_que_suben` — solo alimentos con var_2025 > 5%
4. `Resumen_por_division` — promedios agrupados por categoría de gasto
5. `Serie_historica` — datos en formato largo para series de tiempo
6. `SIPSA_muestra` — muestra de precios mayoristas del DANE

**4 gráficos PNG** listos para incluir en informes.

**`canasta_basica_colombia.sqlite`** con 2 tablas consultables vía SQL.

---

## 🗄️ Consultas SQL incluidas

```sql
-- Alimentos que bajaron en 2025
SELECT alimento, variacion_2025_pct, clasificacion
FROM   ipc_variaciones
WHERE  var_2025 < 0
ORDER  BY var_2025 ASC;

-- Alimentos que más subieron con proyección 2026
SELECT alimento, variacion_2025_pct, proyeccion_2026_pct
FROM   ipc_variaciones
WHERE  var_2025 > 5
ORDER  BY var_2025 DESC;
```

---

## 📈 Visualizaciones

| Gráfico | Descripción |
|---|---|
| ![G1](outputs/grafico1_variacion_2025.png) | Variación anual 2025 por alimento |
| ![G2](outputs/grafico2_series_tiempo.png) | Evolución histórica 2022–2025 |
| ![G3](outputs/grafico3_proyeccion_2026.png) | Variación real vs proyección 2026 |
| ![G4](outputs/grafico4_clasificacion.png) | Clasificación por comportamiento |

---

## 🌐 Fuentes de datos

| Fuente | Descripción | Acceso |
|---|---|---|
| [Open Food Facts](https://world.openfoodfacts.org) | API de productos alimenticios globales | Gratuito, sin registro |
| [SIPSA — datos.gov.co](https://www.datos.gov.co/resource/ugru-ez98.json) | Precios mayoristas agropecuarios DANE | API SODA abierta |
| [IPC DANE](https://www.dane.gov.co/index.php/estadisticas-por-tema/precios-y-costos/indice-de-precios-al-consumidor-ipc) | Variaciones anuales canasta básica | Boletines técnicos públicos |

---

## 📚 Contexto académico

**Módulo:** Lenguajes de Programación en Ciencia de Datos  
**Unidad:** 2 — Análisis de datos y web scraping  
**Componentes evaluados:**
- ✅ Web scraping (API REST)
- ✅ Importación desde dos fuentes (API + JSON)
- ✅ Limpieza y preparación de datos
- ✅ Análisis exploratorio con estadísticas descriptivas
- ✅ Operaciones con data frames (join, pivot, consolidado)
- ✅ Interacción con SQL (SQLite)
- ✅ Exportación CSV y Excel

---

## 👤 Autor

Desarrollado como actividad sumativa del módulo de Lenguajes de Programación en Ciencia de Datos.  
Datos fuente: DANE Colombia · Open Food Facts · IPC 2022–2025.

---

## 📄 Licencia

Este proyecto está bajo la licencia MIT.  
Los datos utilizados provienen de fuentes abiertas con licencias Creative Commons (Open Food Facts — ODbL) y dominio público (DANE Colombia).
