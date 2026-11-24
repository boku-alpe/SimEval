# Berechnung des Omega-Wertes

Dieses Projekt berechnet den Omega-Wert für eine beobachtete Referenzfläche und eine oder mehrere simulierte Flächen.

Die räumlichen Daten können als Shapefile, GeoTIFF oder ESRI-ASCII-Grid eingelesen werden. Das Referenz-Shapefile wird automatisch in das Koordinatensystem des Simulationsrasters transformiert und auf dessen Rastergitter übertragen.

------------------------------------------------------------------------

## Projektstruktur

``` text
Projektordner/
├── omega_analysis.Rmd
├── README.md
├── data/
│   ├── Sattelbach_Deposition_Area_2013.shp
│   ├── Sattelbach_Deposition_Area_2013.shx
│   ├── Sattelbach_Deposition_Area_2013.dbf
│   ├── Sattelbach_Deposition_Area_2013.prj
│   ├── releaseSattelbach_5a68fcffb6_voellmy_FlowThickness.tif
│   ├── releaseSattelbach_529fba6c41_herschelBulkley_FlowThickness.tif
│   ├── releaseSattelbach_1627a228ed_bingham_FlowThickness.tif
│   └── releaseSattelbach_bcce094a04_coulomb_FlowThickness.tif
├── scripts/
│   ├── spatial_functions.R
│   └── OmegaTeval.R
└── results/
    ├── plots/
    └── tables/
```

------------------------------------------------------------------------

## Benötigte Software

Für die Ausführung werden benötigt:

- R
- RStudio
- R Markdown
- Pandoc

Pandoc ist normalerweise bereits in RStudio enthalten.

------------------------------------------------------------------------

## Benötigte R-Pakete

Installieren Sie die benötigten R-Pakete einmalig in der R-Konsole:

``` r
install.packages(
  c(
    "here",
    "raster",
    "sf",
    "sp",
    "knitr",
    "rmarkdown",
    "ggplot2"
  )
)
```

Für den Ternärplot wird zusätzlich das Paket `ggtern` benötigt:

``` r
install.packages("ggtern")
```

------------------------------------------------------------------------

## Eingabedaten

### Referenzdaten

Die Referenzdatei wird in `omega_analysis.Rmd` angegeben:

``` r
single_reference_path <- here::here(
  "data",
  "Sattelbach_Deposition_Area_2013.shp"
)
```

Bei einem Shapefile müssen mindestens folgende Dateien gemeinsam im Ordner `data/` liegen:

``` text
Sattelbach_Deposition_Area_2013.shp
Sattelbach_Deposition_Area_2013.shx
Sattelbach_Deposition_Area_2013.dbf
```

Zusätzlich sollte eine Projek­tionsdatei vorhanden sein:

``` text
Sattelbach_Deposition_Area_2013.prj
```

Die Datei `.prj` enthält die Information über das Koordinatensystem des Shapefiles.

### Simulationsdaten

Eine einzelne Simulation wird beispielsweise so angegeben:

``` r
single_simulation_path <- here::here(
  "data",
  "releaseSattelbach_5a68fcffb6_voellmy_FlowThickness.tif"
)
```

Mehrere Simulationen werden so angegeben:

``` r
multiple_simulation_paths <- c(
  here::here(
    "data",
    "releaseSattelbach_5a68fcffb6_voellmy_FlowThickness.tif"
  ),
  here::here(
    "data",
    "releaseSattelbach_529fba6c41_herschelBulkley_FlowThickness.tif"
  ),
  here::here(
    "data",
    "releaseSattelbach_1627a228ed_bingham_FlowThickness.tif"
  ),
  here::here(
    "data",
    "releaseSattelbach_bcce094a04_coulomb_FlowThickness.tif"
  )
)
```

------------------------------------------------------------------------

## Analysemodus

Der Analysemodus wird in `omega_analysis.Rmd` eingestellt.

### Einzelanalyse

``` r
analysis_mode <- "single"
```

Bei der Einzelanalyse werden eine Referenz und eine Simulation ausgewertet.

### Mehrfachanalyse

``` r
analysis_mode <- "multiple"
```

Bei der Mehrfachanalyse werden eine Referenz und mehrere Simulationen ausgewertet.

Die Anzahl der Simulationspfade, Simulations-IDs und Attributfelder muss identisch sein.

Beispiel:

``` r
multiple_simulation_ids <- c(
  "Voellmy",
  "Herschel-Bulkley",
  "Bingham",
  "Coulomb"
)

multiple_simulation_fields <- list(
  NULL,
  NULL,
  NULL,
  NULL
)
```

------------------------------------------------------------------------

## Schwellenwerte

Die Schwellenwerte werden in `omega_analysis.Rmd` festgelegt:

``` r
thobs <- 0.1
thsim <- 0.1
```

Dabei gilt:

- `thobs`: Schwellenwert für die beobachtete Referenzfläche
- `thsim`: Schwellenwert für die simulierte Fläche

Rasterwerte unterhalb des jeweiligen Schwellenwertes werden bei der Omega-Berechnung nicht als vorhandene Fläche berücksichtigt.

Die geeigneten Schwellenwerte hängen von den Einheiten und Eigenschaften der Daten ab.

------------------------------------------------------------------------

## Koordinatensysteme und Rasteranpassung

Das erste Simulations-TIFF wird als Raster-Template verwendet.

Die Verarbeitung erfolgt in dieser Reihenfolge:

1.  Das Simulations-TIFF wird als Rastervorlage geladen.
2.  Das CRS des TIFFs wird als Ziel-CRS verwendet.
3.  Das Referenz-Shapefile wird automatisch in dieses CRS transformiert.
4.  Das transformierte Shapefile wird auf das TIFF-Raster rasterisiert.
5.  Weitere Simulationen werden auf dasselbe Rastergitter ausgerichtet.
6.  Anschließend wird der Omega-Wert berechnet.

Dadurch besitzen Referenz und Simulation:

- dasselbe Koordinatensystem,
- dieselbe räumliche Ausdehnung,
- dieselbe Rasterauflösung,
- dieselbe Anzahl an Zeilen und Spalten,
- denselben Rasterursprung.

### Wichtig

Das ursprüngliche CRS der Eingabedaten muss korrekt sein.

Bei einem Shapefile sollte daher eine `.prj`-Datei vorhanden sein. Ein fehlendes oder falsches CRS kann nicht zuverlässig automatisch erkannt werden.

------------------------------------------------------------------------

## Externe R-Skripte

Die Datei `omega_analysis.Rmd` lädt zwei externe R-Skripte aus dem Ordner `scripts/`.

### `scripts/spatial_functions.R`

Diese Datei enthält Funktionen zum:

- Einlesen von GeoTIFF- und ASCII-Rastern,
- Einlesen von Shapefiles,
- Prüfen von Koordinatensystemen,
- Transformieren räumlicher Daten,
- Prüfen räumlicher Überschneidungen,
- Ausrichten von Rastern,
- Rasterisieren von Polygonen,
- Erzeugen von Karten,
- Speichern von PNG-Dateien.

### `scripts/OmegaTeval.R`

Diese Datei enthält die Funktion:

``` r
OmegaTeval()
```

Sie berechnet die Omega-Komponenten:

- `alpha`
- `beta`
- `gamma`
- `omega`

Die Funktion wird in der Analyse beispielsweise so aufgerufen:

``` r
OmegaResults <- OmegaTeval(
  obs = depo.obs,
  sim = depo.sim,
  thobs = thobs,
  thsim = thsim
)
```

------------------------------------------------------------------------

## Shapefile-Attribute

Wenn das Referenz-Shapefile als binäre Fläche rasterisiert werden soll, verwenden Sie:

``` r
single_reference_field <- NULL
```

Dann erhalten alle Rasterzellen innerhalb der Shapefile-Fläche den Wert `1`.

Wenn Werte aus einer Attributspalte verwendet werden sollen, kann der Name der Spalte angegeben werden:

``` r
single_reference_field <- "height"
```

Für GeoTIFF- und ASCII-Raster wird kein Attributfeld benötigt:

``` r
single_simulation_field <- NULL
```

------------------------------------------------------------------------

## Analyse ausführen

1.  Öffnen Sie den Projektordner in RStudio.

2.  Öffnen Sie die Datei `omega_analysis.Rmd`.

3.  Prüfen Sie die Dateipfade im Abschnitt `Konfiguration`.

4.  Wählen Sie den Analysemodus:

    ``` r
    analysis_mode <- "single"
    ```

    oder:

    ``` r
    analysis_mode <- "multiple"
    ```

5.  Prüfen Sie die Schwellenwerte.

6.  Speichern Sie die Datei.

7.  Klicken Sie in RStudio auf **Knit**.

Alternativ kann die Datei über die R-Konsole gerendert werden:

``` r
rmarkdown::render(
  "omega_analysis.Rmd"
)
```

------------------------------------------------------------------------

## Ergebnisdateien

Die Ergebnisse werden automatisch im Ordner `results/` gespeichert.

### Ergebnistabellen

Bei einer Einzelanalyse wird folgende Datei erzeugt:

``` text
results/tables/omega_single.csv
```

Bei einer Mehrfachanalyse wird folgende Datei erzeugt:

``` text
results/tables/omega_multiple.csv
```

Die Tabellen enthalten:

- die Simulations-ID,
- `alpha`,
- `beta`,
- `gamma`,
- `omega`.

### Ergebnisgrafiken

Bei einer Einzelanalyse werden folgende Dateien erzeugt:

``` text
results/plots/
├── 01_observed.png
├── 02_simulated.png
├── 03_union_T.png
├── 04_correct_X.png
├── 05_overestimation_O.png
├── 06_underestimation_U.png
└── 07_all_omega_rasters.png
```

Bei einer Mehrfachanalyse wird zusätzlich der Ternärplot erzeugt:

``` text
results/plots/08_ternary_multiple_simulations.png
```

Der Ternärplot wird nur erzeugt, wenn folgender Analysemodus eingestellt ist:

``` r
analysis_mode <- "multiple"
```

------------------------------------------------------------------------

## Bedeutung der Omega-Raster

Die Omega-Auswertung verwendet mehrere Raster:

- `T`: Union von beobachteter und simulierter Fläche
- `X`: korrekte Übereinstimmung
- `O`: Überschätzung
- `U`: Unterschätzung

Die genaue Berechnung dieser Raster ist in der Datei `scripts/OmegaTeval.R` definiert.

------------------------------------------------------------------------

## Omega-Komponenten

Die wichtigsten Ergebniswerte sind:

``` text
alpha
beta
gamma
omega
```

Bei mehreren Simulationen werden die Werte für jede Simulation separat gespeichert.

Die Komponenten werden außerdem im Ternärplot dargestellt.

------------------------------------------------------------------------

## Häufige Fehler

### Datei wurde nicht gefunden

Fehlermeldung:

``` text
Die Datei wurde nicht gefunden
```

Prüfen Sie:

- Dateinamen,
- Dateiendungen,
- Groß- und Kleinschreibung,
- Ordnernamen,
- Projektverzeichnis.

Den aktuellen Projektpfad können Sie prüfen:

``` r
here::here()
```

### Fehler `Objects do not intersect`

Dieser Fehler bedeutet, dass sich zwei räumliche Objekte nicht überschneiden.

Mögliche Ursachen sind:

- unterschiedliche Koordinatensysteme,
- fehlende `.prj`-Datei,
- falsches CRS,
- falsche räumliche Ausdehnung,
- fehlerhafte Georeferenzierung.

Prüfen Sie das CRS eines TIFFs:

``` r
tif <- raster::raster(
  single_simulation_path
)

raster::crs(tif)
raster::extent(tif)
```

Prüfen Sie das CRS des Shapefiles:

``` r
reference <- sf::st_read(
  single_reference_path,
  quiet = TRUE
)

sf::st_crs(reference)
sf::st_bbox(reference)
```

### CRS ist `NA`

Wenn ein Objekt kein CRS besitzt, muss das korrekte ursprüngliche CRS bekannt sein.

Ein CRS darf nicht beliebig gesetzt werden. Dieser Befehl ist nur korrekt, wenn das CRS sicher bekannt ist:

``` r
raster::crs(raster_object) <- "EPSG:XXXX"
```

### Ternärplot wird nicht erzeugt

Prüfen Sie zunächst, ob `ggtern` installiert ist:

``` r
requireNamespace(
  "ggtern",
  quietly = TRUE
)
```

Falls `FALSE` ausgegeben wird:

``` r
install.packages("ggtern")
```

Prüfen Sie außerdem, ob der Analysemodus auf Mehrfachanalyse gesetzt ist:

``` r
analysis_mode <- "multiple"
```

Der R-Code für den Ternärplot darf nicht mit `eval=FALSE` deaktiviert sein.

------------------------------------------------------------------------

## Dateipfade testen

Mit den folgenden Befehlen können Sie prüfen, ob die wichtigsten Dateien gefunden werden:

``` r
file.exists(
  single_reference_path
)

file.exists(
  single_simulation_path
)

file.exists(
  spatial_script
)

file.exists(
  omega_script
)
```

Alle Ausgaben sollten sein:

``` r
[1] TRUE
```

------------------------------------------------------------------------

## Autorinnen und Autoren

Micha Heiser / Christian Scheidl

Projektstand:

``` text
2017 / 2026
```
