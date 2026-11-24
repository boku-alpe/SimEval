---
  title: "Tutorial zur Berechnung des Omega-Wertes"
author: "Micha Heiser, Christian Scheidl"
date: "2017/2026"
output:
  pdf_document:
  fig_caption: true
---
  
  ```{r setup, include=FALSE}
knitr::opts_chunk$set(
  echo = TRUE,
  warning = FALSE,
  message = FALSE
)

# Benötigte Pakete laden
library(here)
library(raster)
library(rgdal)

# ------------------------------------------------------------
# Projektverzeichnis
# ------------------------------------------------------------
#
# Das Projektverzeichnis wird automatisch mit here::here()
# erkannt. Voraussetzung ist zum Beispiel eine .Rproj-Datei
# im Projektordner.
#
# Alle Pfade werden relativ zu diesem Projektordner angegeben.
# Es werden keine absoluten Pfade benötigt.

project_directory <- here::here()

data_directory <- here::here("data")
script_directory <- here::here("scripts")

# ------------------------------------------------------------
# OmegaTeval-Funktion laden
# ------------------------------------------------------------

omega_script <- here::here(
  "scripts",
  "OmegaTeval.R"
)

if (!file.exists(omega_script)) {
  stop(
    "Das Skript 'OmegaTeval.R' wurde nicht gefunden:\n",
    omega_script
  )
}

source(omega_script)
```

# 1. Eingabedaten

Für die Berechnung des \(\Omega_T\)-Wertes werden folgende Eingaben benötigt:
  
  1. ein Raster der beobachteten beziehungsweise referenzierten Ablagerungsfläche,
2. ein Raster der simulierten Ablagerungsfläche,
3. ein Schwellenwert für die Referenzfläche,
4. ein Schwellenwert für die Simulationsfläche.

Die Referenz- und Simulationsdaten können als folgende Dateiformate vorliegen:
  
  - ESRI-Shapefile: `.shp`
- ESRI-ASCII-Grid: `.asc` oder `.ascii`
- GeoTIFF: `.tif` oder `.tiff`

Unabhängig vom ursprünglichen Dateiformat müssen die Daten vor der Berechnung als Rasterobjekte des Pakets `raster` vorliegen.

Shapefiles werden mit `rasterize()` rasterisiert. ASCII-Dateien und GeoTIFF-Dateien werden direkt als Raster eingelesen.

# 2. Funktion zum Einlesen der Daten

Die folgende Funktion erkennt das Dateiformat automatisch.

Bei Rasterdateien wird die Datei direkt eingelesen. Bei Shapefiles wird die Geometrie auf ein Raster übertragen.

Wird ein `template` angegeben, wird dieses Raster als Vorlage verwendet. Dadurch erhalten Referenz- und Simulationsraster dieselbe Ausdehnung, Auflösung und Rasterausrichtung.

```{r import-function}
load_spatial_data <- function(
    path,
    template = NULL,
    field = NULL,
    resolution = c(1, 1),
    background = 0
) {
  
  # Prüfen, ob die Datei existiert
  if (!file.exists(path)) {
    stop(
      "Die angegebene Datei wurde nicht gefunden:\n",
      path
    )
  }
  
  # Dateiendung bestimmen
  extension <- tolower(
    tools::file_ext(path)
  )
  
  # ----------------------------------------------------------
  # GeoTIFF und ESRI ASCII Grid
  # ----------------------------------------------------------
  
  if (extension %in% c("tif", "tiff", "asc", "ascii")) {
    
    # Raster direkt einlesen
    result <- raster(path)
    
    # Falls ein Template vorhanden ist, überprüfen,
    # ob beide Raster räumlich übereinstimmen.
    if (!is.null(template)) {
      
      same_grid <- compareRaster(
        result,
        template,
        extent = TRUE,
        rowcol = TRUE,
        crs = TRUE,
        res = TRUE,
        orig = TRUE,
        rotation = TRUE,
        values = FALSE,
        stopiffalse = FALSE
      )
      
      # Falls die Raster nicht übereinstimmen,
      # wird das Raster an das Template angepasst.
      if (!isTRUE(same_grid)) {
        
        # bilinear ist für kontinuierliche Werte geeignet,
        # zum Beispiel Ablagerungshöhen.
        result <- resample(
          result,
          template,
          method = "bilinear"
        )
      }
    }
    
    return(result)
  }
  
  # ----------------------------------------------------------
  # Shapefile
  # ----------------------------------------------------------
  
  if (extension == "shp") {
    
    # Shapefile einlesen
    shp <- readOGR(
      dsn = dirname(path),
      layer = tools::file_path_sans_ext(
        basename(path)
      ),
      verbose = FALSE
    )
    
    # Wenn kein Template vorhanden ist, wird ein neues Raster
    # anhand der Ausdehnung des Shapefiles erzeugt.
    if (is.null(template)) {
      
      template <- raster()
      
      extent(template) <- extent(shp)
      res(template) <- resolution
      
      # CRS des Shapefiles übernehmen
      if (!is.na(crs(shp))) {
        crs(template) <- crs(shp)
      }
    }
    
    # Wenn kein Attributfeld angegeben wurde,
    # wird binär mit dem Wert 1 rasterisiert.
    if (is.null(field)) {
      field <- 1
    }
    
    # Shapefile rasterisieren
    result <- rasterize(
      shp,
      template,
      field = field,
      background = background
    )
    
    return(result)
  }
  
  # Nicht unterstützte Dateiendung
  stop(
    "Nicht unterstütztes Dateiformat: .",
    extension,
    "\nUnterstützte Formate sind: ",
    ".shp, .asc, .ascii, .tif und .tiff"
  )
}
```

# 3. Hinweise zur Verwendung von Shapefiles

Ein Shapefile besteht normalerweise aus mehreren Dateien:
  
  ```text
datei.shp
datei.shx
datei.dbf
datei.prj
```

Diese Dateien müssen im selben Verzeichnis liegen.

## Binäres Shapefile

Wenn nur die Fläche und nicht ein Attributwert des Shapefiles verwendet werden soll, wird das Shapefile binär rasterisiert:
  
  ```r
depo.obs <- load_spatial_data(
  path = here::here("data", "referenz.shp"),
  field = 1,
  resolution = c(1, 1),
  background = 0
)
```

Dabei gilt:
  
  - innerhalb der Fläche: Wert `1`,
- außerhalb der Fläche: Wert `0`.

## Shapefile mit Attributfeld

Wenn die Werte aus einer Attributspalte stammen, wird der Name der Spalte als `field` angegeben:
  
  ```r
depo.sim <- load_spatial_data(
  path = here::here("data", "simulation_01.shp"),
  template = depo.obs,
  field = "param",
  background = 0
)
```

Die verfügbaren Attributspalten können folgendermaßen angezeigt werden:
  
  ```{r inspect-shapefile, eval=FALSE}
shp <- readOGR(
  dsn = here::here("data"),
  layer = "simulation_01",
  verbose = FALSE
)

names(shp@data)
head(shp@data)
```

# 4. Eine Simulation laden

Im folgenden Beispiel wird eine Referenzdatei und eine Simulationsdatei aus dem Ordner `data/` geladen.

Die Dateien können unterschiedliche Formate besitzen.

Beispiel:
  
  - Referenzfläche: `referenz.tif`
- Simulation: `simulation_01.asc`

```{r single-file-paths}
reference_path <- here::here(
  "data",
  "referenz.tif"
)

simulation_path <- here::here(
  "data",
  "simulation_01.asc"
)
```

Die beiden Dateien können selbstverständlich auch andere unterstützte Formate besitzen:
  
  ```r
reference_path <- here::here("data", "referenz.shp")
simulation_path <- here::here("data", "simulation_01.tiff")
```

oder:
  
  ```r
reference_path <- here::here("data", "referenz.asc")
simulation_path <- here::here("data", "simulation_01.shp")
```

## Referenzraster laden

Wenn die Referenzdatei ein GeoTIFF oder ESRI-ASCII-Grid ist:
  
  ```{r load-reference-raster, eval=FALSE}
depo.obs <- load_spatial_data(
  path = reference_path
)
```

Wenn die Referenzdatei ein Shapefile ist und binär rasterisiert werden soll:
  
  ```{r load-reference-shapefile, eval=FALSE}
depo.obs <- load_spatial_data(
  path = reference_path,
  field = 1,
  resolution = c(1, 1),
  background = 0
)
```

## Simulationsraster laden

Das Referenzraster wird als Vorlage verwendet:
  
  ```{r load-simulation-raster, eval=FALSE}
depo.sim <- load_spatial_data(
  path = simulation_path,
  template = depo.obs
)
```

Wenn das Simulations-Shapefile Werte aus der Attributspalte `param` verwenden soll:
  
  ```{r load-simulation-shapefile, eval=FALSE}
depo.sim <- load_spatial_data(
  path = simulation_path,
  template = depo.obs,
  field = "param",
  background = 0
)
```

## Referenz- und Simulationsraster überprüfen

```{r check-single-raster, eval=FALSE}
depo.obs
depo.sim
```

Die räumlichen Eigenschaften können mit `compareRaster()` überprüft werden:
  
  ```{r compare-single-raster, eval=FALSE}
compareRaster(
  depo.obs,
  depo.sim,
  extent = TRUE,
  rowcol = TRUE,
  crs = TRUE,
  res = TRUE,
  orig = TRUE,
  rotation = TRUE,
  values = FALSE
)
```

## Referenz- und Simulationsraster darstellen

```{r plot-single-raster, fig.cap="Referenzfläche und Simulationsfläche"}
plot(
  depo.obs,
  legend = FALSE,
  col = "blue",
  main = "Referenz- und Simulationsfläche"
)

plot(
  depo.sim,
  legend = FALSE,
  add = TRUE,
  col = "red",
  alpha = 0.5
)
```

# 5. Omega-Wert für eine Simulation berechnen

Die Funktion `OmegaTeval()` befindet sich in der Datei:
  
  ```text
scripts/OmegaTeval.R
```

Die Funktion wird im Setup-Chunk mit `source()` geladen.

In diesem Beispiel werden für die Referenz- und Simulationsdaten Schwellenwerte von `0.1` verwendet:
  
  ```{r calculate-omega, eval=FALSE}
OmegaResults <- OmegaTeval(
  depo.obs,
  depo.sim,
  0.1,
  0.1
)
```

Die Funktion liefert eine Liste mit folgenden Bestandteilen:
  
  - `T`: Vereinigungsfläche aus Referenz und Simulation,
- `X`: korrekt simulierte Fläche,
- `O`: überschätzte Fläche,
- `U`: unterschätzte Fläche,
- `Omega`: Vektor mit den Werten \(\alpha\), \(\beta\), \(\gamma\) und \(\Omega_T\).

Die Kennwerte können folgendermaßen ausgegeben werden:
  
  ```{r show-omega-values, eval=FALSE}
OmegaResults$Omega
```

# 6. Ergebnisse darstellen

Zunächst wird das Simulationsraster anhand des Schwellenwertes klassifiziert.

```{r prepare-result-plot, eval=FALSE}
# Schwellenwert auf das Simulationsraster anwenden
depo.simth <- depo.sim

values(depo.simth) <- values(depo.simth) >= 0.1

# Werte unterhalb des Schwellenwertes auf NA setzen
values(depo.simth)[
  values(depo.simth) == FALSE
] <- NA
```

Die Ergebnisraster werden zu einem RasterStack zusammengefasst:
  
  ```{r stack-result-raster, eval=FALSE}
plotstack <- stack(
  depo.obs,
  depo.simth,
  OmegaResults$T,
  OmegaResults$X,
  OmegaResults$O,
  OmegaResults$U
)

names(plotstack) <- c(
  "Ref",
  "Sim",
  "T",
  "X",
  "O",
  "U"
)
```

```{r plot-result-raster, fig.cap="Ergebnis der Omega-Wert-Berechnung", eval=FALSE}
plot(plotstack)
```

# 7. Mehrere Simulationen

Für mehrere Simulationen wird eine Metadatentabelle verwendet.

Die Dateien liegen in diesem Beispiel direkt im Ordner `data/`. Ein zusätzlicher Unterordner `simulations/` ist nicht erforderlich.

Die Datei `metadatasimulations.csv` kann beispielsweise folgende Struktur besitzen:
  
  ```text
ID,model,mu,filename,fielddepositionheight
S1,RAMMS,0.10,simulation_01.tif,param
S2,RAMMS,0.20,simulation_02.asc,param
S3,RAMMS,0.30,simulation_03.shp,param
S4,FLO-2D,0.20,simulation_04.tiff,param
S5,FLO-2D,0.30,simulation_05.shp,param
```

Die Spalten bedeuten:
  
  - `ID`: eindeutige ID der Simulation,
- `model`: verwendetes Simulationsmodell,
- `mu`: Beispiel für einen Modellparameter,
- `filename`: Dateiname der Simulation,
- `fielddepositionheight`: Attributfeld im Shapefile.

Für Rasterdateien wird `fielddepositionheight` nicht benötigt. Für Shapefiles muss dort entweder ein Attributfeldname oder ein leerer Wert stehen.

## Metadatentabelle laden

```{r load-metadata}
metadata_path <- here::here(
  "data",
  "metadatasimulations.csv"
)

if (!file.exists(metadata_path)) {
  stop(
    "Die Metadatendatei wurde nicht gefunden:\n",
    metadata_path
  )
}

metasim <- read.csv(
  metadata_path,
  encoding = "UTF-8",
  stringsAsFactors = FALSE
)

metasim
```

Falls Ihre Metadatendatei `.txt` heißt, kann sie zum Beispiel so geladen werden:
  
  ```r
metasim <- read.csv(
  here::here(
    "data",
    "metadatasimulations.txt"
  ),
  header = TRUE,
  sep = ",",
  encoding = "UTF-8",
  stringsAsFactors = FALSE
)
```

# 8. Referenzraster für mehrere Simulationen laden

Die Referenzdatei wird einmal geladen und anschließend als Rastervorlage für alle Simulationen verwendet.

Beispiel für eine Referenzdatei im GeoTIFF-Format:
  
  ```{r load-reference-multiple, eval=FALSE}
reference_path <- here::here(
  "data",
  "referenz.tif"
)

depo.obs <- load_spatial_data(
  path = reference_path
)
```

Beispiel für eine Referenzdatei als Shapefile:
  
  ```r
reference_path <- here::here(
  "data",
  "referenz.shp"
)

depo.obs <- load_spatial_data(
  path = reference_path,
  field = 1,
  resolution = c(1, 1),
  background = 0
)
```

# 9. RasterStack mit mehreren Simulationen erzeugen

Die Dateien werden direkt aus dem Ordner `data/` geladen.

```{r build-raster-stack, eval=FALSE}
n <- nrow(metasim)

# Leere Liste für die Simulationsraster erstellen
simulation_layers <- vector(
  mode = "list",
  length = n
)

for (i in seq_len(n)) {
  
  # Dateipfad relativ zum Projektordner erstellen
  simulation_path <- here::here(
    "data",
    metasim$filename[i]
  )
  
  if (!file.exists(simulation_path)) {
    stop(
      "Simulationsdatei wurde nicht gefunden:\n",
      simulation_path
    )
  }
  
  # Dateiendung feststellen
  extension <- tolower(
    tools::file_ext(simulation_path)
  )
  
  # Attributfeld ist nur bei Shapefiles relevant
  field_i <- NULL
  
  if (extension == "shp") {
    
    # Attributfeld aus der Metadatentabelle lesen
    field_i <- metasim$fielddepositionheight[i]
    
    # Wenn kein Attributfeld angegeben ist,
    # wird binär mit dem Wert 1 rasterisiert.
    if (
      is.na(field_i) ||
      field_i == ""
    ) {
      field_i <- 1
    }
  }
  
  # Simulation laden und an depo.obs ausrichten
  simulation_layers[[i]] <- load_spatial_data(
    path = simulation_path,
    template = depo.obs,
    field = field_i,
    background = 0
  )
  
  # Layernamen anhand der ID setzen
  names(simulation_layers[[i]]) <- metasim$ID[i]
}

# Einzelne Raster zu einem RasterStack zusammenfassen
depo.sim <- stack(
  simulation_layers
)
```

## RasterStack überprüfen

```{r inspect-raster-stack, eval=FALSE}
depo.sim
```

Anzahl der Layer:
  
  ```{r number-of-layers, eval=FALSE}
nlayers(depo.sim)
```

Namen der Layer:
  
  ```{r layer-names, eval=FALSE}
names(depo.sim)
```

## RasterStack darstellen

```{r plot-raster-stack, fig.cap="RasterStack mit mehreren Simulationen", eval=FALSE}
plot(depo.sim)
```

# 10. Omega-Werte für alle Simulationen berechnen

Zunächst wird ein Dataframe für die Ergebnisse angelegt:
  
  ```{r create-omega-dataframe, eval=FALSE}
n <- nlayers(depo.sim)

dat.omega <- data.frame(
  ID = rep(NA_character_, n),
  alpha = rep(NA_real_, n),
  beta = rep(NA_real_, n),
  gamma = rep(NA_real_, n),
  omega = rep(NA_real_, n),
  stringsAsFactors = FALSE
)
```

Anschließend wird für jeden Layer des RasterStacks der Omega-Wert berechnet.

In diesem Beispiel wird der Schwellenwert der Referenzfläche auf `0` gesetzt. Der Schwellenwert der Simulation wird als 10%-Quantil der jeweiligen Simulationswerte bestimmt.

```{r calculate-omega-all-simulations, eval=FALSE}
for (i in seq_len(n)) {
  
  # Schwellenwert für die Referenzfläche
  thobs <- 0
  
  # Schwellenwert für die Simulation:
  # 10%-Quantil der Simulationswerte
  thsim <- quantile(
    values(depo.sim[[i]]),
    probs = 0.1,
    na.rm = TRUE
  )
  
  # Omega-Wert berechnen
  omega_i <- OmegaTeval(
    depo.obs,
    depo.sim[[i]],
    thobs,
    thsim
  )$Omega
  
  # Ergebnisse speichern
  dat.omega$ID[i] <- names(
    depo.sim[[i]]
  )
  
  dat.omega[
    i,
    c("alpha", "beta", "gamma", "omega")
  ] <- omega_i
}

dat.omega
```

Wenn für alle Simulationen derselbe Schwellenwert verwendet werden soll, kann stattdessen folgender Code verwendet werden:
  
  ```{r calculate-omega-fixed-threshold, eval=FALSE}
for (i in seq_len(n)) {
  
  # Feste Schwellenwerte
  thobs <- 0.1
  thsim <- 0.1
  
  # Omega-Wert berechnen
  omega_i <- OmegaTeval(
    depo.obs,
    depo.sim[[i]],
    thobs,
    thsim
  )$Omega
  
  # Ergebnisse speichern
  dat.omega$ID[i] <- names(
    depo.sim[[i]]
  )
  
  dat.omega[
    i,
    c("alpha", "beta", "gamma", "omega")
  ] <- omega_i
}

dat.omega
```

# 11. Metadaten und Omega-Werte zusammenführen

Die Ergebnistabelle wird mit den Metadaten verbunden:
  
  ```{r merge-results-metadata, eval=FALSE}
dat.plot <- merge(
  metasim,
  dat.omega,
  by = "ID"
)

dat.plot
```

# 12. Ternärer Plot

Für den ternären Plot wird das Paket `ggtern` benötigt:
  
  ```{r load-ggtern, eval=FALSE}
library(ggtern)
```

Die drei Achsen zeigen die Omega-Komponenten:
  
  - \(\alpha\),
- \(\beta\),
- \(\gamma\).

```{r ternary-plot, fig.cap="Ternärer Plot der Omega-Komponenten", eval=FALSE}
ggtern(
  data = dat.plot,
  aes(
    x = beta,
    y = alpha,
    z = gamma
  )
) +
  geom_point(
    aes(
      shape = model,
      colour = mu
    ),
    size = 2
  )
```

# 13. Erweiterter ternärer Plot

Die folgenden Daten definieren Bereiche, in denen jeweils eine Omega-Komponente mindestens den Wert `0.5` besitzt.

```{r ternary-regions, eval=FALSE}
# Bereich alpha >= 0.5
dat.alpha <- data.frame(
  beta = c(0.5, 0, 0),
  alpha = c(0.5, 0.5, 1),
  gamma = c(0, 0.5, 0)
)

# Bereich beta >= 0.5
dat.beta <- data.frame(
  beta = c(1, 0.5, 0.5),
  alpha = c(0, 0, 0.5),
  gamma = c(0, 0.5, 0)
)

# Bereich gamma >= 0.5
dat.gamma <- data.frame(
  beta = c(0, 0.5, 0),
  alpha = c(0, 0, 0.5),
  gamma = c(1, 0.5, 0.5)
)

# Linie für Omega_T >= 0
dat.line <- data.frame(
  beta = c(0.5, 0),
  alpha = c(0.5, 0.5),
  gamma = c(0, 0.5)
)
```

```{r extended-ternary-plot, fig.cap="Erweiterter ternärer Plot der Omega-Komponenten", eval=FALSE}
ggtern(
  data = dat.plot,
  aes(
    x = beta,
    y = alpha,
    z = gamma
  )
) +
  geom_polygon(
    data = dat.alpha,
    colour = "grey",
    alpha = 0.10
  ) +
  geom_polygon(
    data = dat.beta,
    colour = "grey",
    alpha = 0.05
  ) +
  geom_polygon(
    data = dat.gamma,
    colour = "grey",
    alpha = 0.05
  ) +
  geom_line(
    data = dat.line,
    linewidth = 1
  ) +
  annotate(
    "text",
    x = 0.65,
    y = 0.2,
    z = 0.15,
    label = "beta >= 0.5"
  ) +
  annotate(
    "text",
    x = 0.15,
    y = 0.2,
    z = 0.65,
    label = "gamma >= 0.5"
  ) +
  annotate(
    "text",
    x = 0.1,
    y = 0.8,
    z = 0.1,
    label = "alpha >= 0.5"
  ) +
  annotate(
    "text",
    x = 0.25,
    y = 0.45,
    z = 0.25,
    label = "Omega_T >= 0"
  ) +
  geom_point(
    aes(
      shape = model,
      colour = mu
    ),
    size = 2
  )
```

# 14. Ergebnisse exportieren

Die Rasterergebnisse einer Einzelberechnung können als GeoTIFF-Dateien in den Ordner `data/` geschrieben werden:
  
  ```{r export-single-results, eval=FALSE}
writeRaster(
  OmegaResults$T,
  filename = here::here(
    "data",
    "omega_T.tif"
  ),
  format = "GTiff",
  overwrite = TRUE
)

writeRaster(
  OmegaResults$X,
  filename = here::here(
    "data",
    "omega_X.tif"
  ),
  format = "GTiff",
  overwrite = TRUE
)

writeRaster(
  OmegaResults$O,
  filename = here::here(
    "data",
    "omega_O.tif"
  ),
  format = "GTiff",
  overwrite = TRUE
)

writeRaster(
  OmegaResults$U,
  filename = here::here(
    "data",
    "omega_U.tif"
  ),
  format = "GTiff",
  overwrite = TRUE
)
```

Die Omega-Kennwerte können als CSV-Datei gespeichert werden:
  
  ```{r export-omega-values, eval=FALSE}
write.csv(
  dat.omega,
  file = here::here(
    "data",
    "omega_values.csv"
  ),
  row.names = FALSE
)
```

# 15. Zusammenfassung

Die Eingabedateien werden relativ zum Projektordner angegeben:
  
  ```r
reference_path <- here::here(
  "data",
  "referenz.tif"
)

simulation_path <- here::here(
  "data",
  "simulation_01.asc"
)
```

Unterstützte Formate sind:
  
  ```r
.shp
.asc
.ascii
.tif
.tiff
```

Die Dateien werden mit der Importfunktion eingelesen:
  
  ```r
depo.obs <- load_spatial_data(
  reference_path
)

depo.sim <- load_spatial_data(
  simulation_path,
  template = depo.obs
)
```

Die Omega-Berechnung erfolgt anschließend unverändert:
  
  ```r
OmegaResults <- OmegaTeval(
  depo.obs,
  depo.sim,
  0.1,
  0.1
)
```

Für mehrere Simulationen müssen die Dateinamen in `metadatasimulations.csv` eingetragen werden. Die Dateien werden dabei direkt aus dem Ordner `data/` geladen:
  
  ```r
simulation_path <- here::here(
  "data",
  metasim$filename[i]
)
```

Ein zusätzlicher Unterordner `simulations/` ist nicht erforderlich.