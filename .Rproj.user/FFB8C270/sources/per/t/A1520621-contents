# ============================================================
# Räumliche Hilfsfunktionen für Omega-Auswertung
# ============================================================

# ------------------------------------------------------------
# CRS prüfen
# ------------------------------------------------------------

check_crs <- function(
    spatial_object,
    object_name = "Räumliches Objekt"
) {
  
  object_crs <- raster::crs(
    spatial_object
  )
  
  if (is.na(object_crs)) {
    stop(
      object_name,
      " besitzt kein gültiges CRS."
    )
  }
  
  invisible(TRUE)
}


# ------------------------------------------------------------
# Prüfen, ob zwei räumliche Objekte überlappen
# ------------------------------------------------------------

check_spatial_overlap <- function(
    object_1,
    object_2,
    object_1_name = "Objekt 1",
    object_2_name = "Objekt 2"
) {
  
  overlapping_extent <- tryCatch(
    raster::intersect(
      raster::extent(object_1),
      raster::extent(object_2)
    ),
    error = function(e) {
      NULL
    }
  )
  
  if (is.null(overlapping_extent)) {
    stop(
      "\nDie räumlichen Objekte überschneiden sich nicht.\n\n",
      object_1_name,
      ":\n",
      as.character(
        raster::extent(object_1)
      ),
      "\n\n",
      object_2_name,
      ":\n",
      as.character(
        raster::extent(object_2
        )
      )
    )
  }
  
  invisible(overlapping_extent)
}


# ------------------------------------------------------------
# Raster exakt an Template anpassen
# ------------------------------------------------------------

align_raster_to_template <- function(
    raster_object,
    template,
    method = "bilinear"
) {
  
  check_crs(
    raster_object,
    "Eingangsraster"
  )
  
  check_crs(
    template,
    "Raster-Template"
  )
  
  # CRS vergleichen
  same_crs <- raster::compareCRS(
    raster_object,
    template
  )
  
  # Bei unterschiedlichem CRS zunächst projizieren
  if (!isTRUE(same_crs)) {
    
    raster_object <- raster::projectRaster(
      from = raster_object,
      to = template,
      method = method
    )
  }
  
  # Nach der Projektion muss eine Überlappung bestehen
  check_spatial_overlap(
    raster_object,
    template,
    object_1_name = "Transformiertes Raster",
    object_2_name = "Raster-Template"
  )
  
  # Exakt auf Template-Gitter bringen
  raster_compatible <- raster::compareRaster(
    raster_object,
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
  
  if (!isTRUE(raster_compatible)) {
    
    raster_object <- raster::resample(
      raster_object,
      template,
      method = method
    )
  }
  
  return(raster_object)
}


# ------------------------------------------------------------
# Rasterdatei laden
# ------------------------------------------------------------

load_raster_data <- function(
    path,
    template = NULL,
    source_crs = NULL,
    resample_method = "bilinear"
) {
  
  if (!file.exists(path)) {
    stop(
      "Rasterdatei wurde nicht gefunden:\n",
      path
    )
  }
  
  raster_object <- raster::raster(
    path
  )
  
  # CRS nur deklarieren, wenn es fehlt und explizit angegeben wurde
  if (
    is.na(raster::crs(raster_object)) &&
    !is.null(source_crs)
  ) {
    raster::crs(raster_object) <- source_crs
  }
  
  check_crs(
    raster_object,
    paste0("Rasterdatei: ", basename(path))
  )
  
  # Wenn kein Template angegeben wurde, Raster direkt zurückgeben
  if (is.null(template)) {
    return(raster_object)
  }
  
  raster_object <- align_raster_to_template(
    raster_object = raster_object,
    template = template,
    method = resample_method
  )
  
  return(raster_object)
}


# ------------------------------------------------------------
# Shapefile laden und auf Raster-Template rasterisieren
# ------------------------------------------------------------

load_shapefile_data <- function(
    path,
    template,
    field = NULL,
    background = 0,
    source_crs = NULL
) {
  
  if (!file.exists(path)) {
    stop(
      "Shapefile wurde nicht gefunden:\n",
      path
    )
  }
  
  if (is.null(template)) {
    stop(
      "Für ein Shapefile muss ein Raster-Template angegeben werden."
    )
  }
  
  check_crs(
    template,
    "Raster-Template"
  )
  
  shp <- sf::st_read(
    dsn = path,
    quiet = TRUE
  )
  
  if (nrow(shp) == 0) {
    stop(
      "Das Shapefile enthält keine Datensätze:\n",
      path
    )
  }
  
  # Fehlendes CRS behandeln
  if (is.na(sf::st_crs(shp))) {
    
    if (is.null(source_crs)) {
      stop(
        "Das Shapefile besitzt kein CRS:\n",
        path,
        "\n\n",
        "Bitte geben Sie source_crs an."
      )
    }
    
    # Nur deklarieren, nicht transformieren
    shp <- sf::st_set_crs(
      shp,
      source_crs
    )
  }
  
  shp <- sf::st_make_valid(
    shp
  )
  
  empty_geometry <- sf::st_is_empty(
    shp
  )
  
  if (any(empty_geometry)) {
    shp <- shp[
      !empty_geometry,
      ,
      drop = FALSE
    ]
  }
  
  if (nrow(shp) == 0) {
    stop(
      "Das Shapefile enthält keine gültigen Geometrien:\n",
      path
    )
  }
  
  # Ziel-CRS des Templates
  template_crs <- raster::projection(
    template
  )
  
  # Shapefile in Template-CRS transformieren
  shp <- sf::st_transform(
    shp,
    crs = template_crs
  )
  
  # In Spatial-Objekt umwandeln
  shp_sp <- methods::as(
    shp,
    "Spatial"
  )
  
  # Überlappung prüfen
  check_spatial_overlap(
    shp_sp,
    template,
    object_1_name = "Transformiertes Shapefile",
    object_2_name = "Raster-Template"
  )
  
  # NULL bedeutet binäre Rasterisierung
  if (is.null(field)) {
    field <- 1
  }
  
  if (
    is.character(field) &&
    !(field %in% names(shp_sp))
  ) {
    stop(
      "Das Attributfeld '",
      field,
      "' wurde nicht gefunden.\n\n",
      "Verfügbare Felder:\n",
      paste(
        names(shp_sp),
        collapse = ", "
      )
    )
  }
  
  result <- raster::rasterize(
    x = shp_sp,
    y = template,
    field = field,
    background = background
  )
  
  return(result)
}


# ------------------------------------------------------------
# Allgemeine Importfunktion
# ------------------------------------------------------------

load_spatial_data <- function(
    path,
    template = NULL,
    field = NULL,
    background = 0,
    source_crs = NULL,
    resample_method = "bilinear"
) {
  
  extension <- tolower(
    tools::file_ext(path)
  )
  
  if (
    extension %in% c(
      "tif",
      "tiff",
      "asc",
      "ascii"
    )
  ) {
    
    return(
      load_raster_data(
        path = path,
        template = template,
        source_crs = source_crs,
        resample_method = resample_method
      )
    )
  }
  
  if (extension == "shp") {
    
    return(
      load_shapefile_data(
        path = path,
        template = template,
        field = field,
        background = background,
        source_crs = source_crs
      )
    )
  }
  
  stop(
    "Nicht unterstütztes Dateiformat: .",
    extension,
    "\nUnterstützt werden: .shp, .tif, .tiff, .asc und .ascii"
  )
}


# ------------------------------------------------------------
# Raster für Darstellung vorbereiten
# ------------------------------------------------------------

prepare_plot_raster <- function(
    raster_object,
    threshold
) {
  
  result <- raster_object
  
  raster::values(result) <- ifelse(
    !is.na(raster::values(result)) &
      raster::values(result) >= threshold,
    1,
    NA
  )
  
  return(result)
}


# ------------------------------------------------------------
# Rasterkarte speichern
# ------------------------------------------------------------

save_raster_plot <- function(
    raster_object,
    filename,
    title,
    colour,
    plot_directory
) {
  
  png(
    filename = file.path(
      plot_directory,
      filename
    ),
    width = 1800,
    height = 1400,
    res = 200
  )
  
  plot(
    raster_object,
    legend = FALSE,
    col = colour,
    main = title
  )
  
  dev.off()
}


# ------------------------------------------------------------
# Übersicht der Omega-Raster speichern
# ------------------------------------------------------------

save_raster_overview <- function(
    observed_raster,
    simulated_raster,
    omega_results,
    filename,
    plot_directory
) {
  
  png(
    filename = file.path(
      plot_directory,
      filename
    ),
    width = 2400,
    height = 3000,
    res = 200
  )
  
  old_par <- par(
    no.readonly = TRUE
  )
  
  on.exit(
    par(old_par),
    add = TRUE
  )
  
  par(
    mfrow = c(3, 2),
    mar = c(2, 2, 3, 2)
  )
  
  plot(
    observed_raster,
    legend = FALSE,
    col = "lightblue",
    main = "Observed"
  )
  
  plot(
    simulated_raster,
    legend = FALSE,
    col = "salmon",
    main = "Simulated"
  )
  
  plot(
    omega_results$T,
    legend = FALSE,
    col = "grey50",
    main = "T: Union"
  )
  
  plot(
    omega_results$X,
    legend = FALSE,
    col = "darkgreen",
    main = "X: Correct"
  )
  
  plot(
    omega_results$O,
    legend = FALSE,
    col = "orange",
    main = "O: Overestimation"
  )
  
  plot(
    omega_results$U,
    legend = FALSE,
    col = "purple",
    main = "U: Underestimation"
  )
  
  dev.off()
}