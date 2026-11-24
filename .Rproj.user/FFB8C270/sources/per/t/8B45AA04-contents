OmegaTeval <- function(
    obs,
    sim,
    thobs,
    thsim,
    domain = obs,
    all = FALSE
) {
  
  ########################################################################
  # Function for calculating the Omega value proposed by
  # DOI:10.1007/s10596-016-9609-9, equation (7).
  #
  # INPUT:
  #   obs:    raster object of measured deposition height [m]
  #   sim:    raster object of simulated deposition height [m]
  #   thobs:  threshold for observed deposition height [m]
  #   thsim:  threshold for simulated deposition height [m]
  #   domain: spatial object defining the calculation domain
  #   all:    return additional error measures if TRUE
  #
  # OUTPUT:
  #   T:          raster of the union of observed and simulated area
  #   X:          raster of correctly predicted pixels
  #   U:          raster of underestimated pixels
  #   O:          raster of overestimated pixels
  #   Omega:      vector containing alpha, beta, gamma and omegaT
  ########################################################################
  
  # ------------------------------------------------------------
  # Eingaben kopieren
  # ------------------------------------------------------------
  
  obsBin <- obs
  simBin <- sim
  
  # ------------------------------------------------------------
  # Raster auf die gemeinsame Domäne begrenzen
  # ------------------------------------------------------------
  
  domainEX <- extent(domain)
  
  # Gemeinsame Schnittfläche bestimmen:
  #
  # xmin und ymin müssen möglichst groß sein,
  # xmax und ymax möglichst klein.
  xmin <- max(
    domainEX[1],
    extent(simBin)[1],
    extent(obsBin)[1]
  )
  
  xmax <- min(
    domainEX[2],
    extent(simBin)[2],
    extent(obsBin)[2]
  )
  
  ymin <- max(
    domainEX[3],
    extent(simBin)[3],
    extent(obsBin)[3]
  )
  
  ymax <- min(
    domainEX[4],
    extent(simBin)[4],
    extent(obsBin)[4]
  )
  
  # Prüfen, ob eine gültige gemeinsame Ausdehnung vorhanden ist
  if (xmin >= xmax || ymin >= ymax) {
    stop(
      "Die Raster besitzen keine gemeinsame räumliche Ausdehnung."
    )
  }
  
  domainEX <- extent(
    xmin,
    xmax,
    ymin,
    ymax
  )
  
  # Raster auf die gemeinsame Ausdehnung zuschneiden
  simBin <- crop(
    simBin,
    domainEX
  )
  
  obsBin <- crop(
    obsBin,
    domainEX
  )
  
  # ------------------------------------------------------------
  # Raster aneinander anpassen
  # ------------------------------------------------------------
  
  if (
    !compareRaster(
      simBin,
      obsBin,
      extent = TRUE,
      rowcol = TRUE,
      crs = TRUE,
      res = TRUE,
      orig = TRUE,
      rotation = TRUE,
      values = FALSE,
      stopiffalse = FALSE
    )
  ) {
    
    # Simulation auf das Beobachtungsraster übertragen
    simBin <- resample(
      simBin,
      obsBin,
      method = "ngb"
    )
  }
  
  # ------------------------------------------------------------
  # Beobachtungsraster binarisieren
  # ------------------------------------------------------------
  
  obsBin[obsBin >= thobs] <- 1
  obsBin[obsBin < thobs] <- NA
  
  # ------------------------------------------------------------
  # Simulationsraster binarisieren
  # ------------------------------------------------------------
  
  simBin[simBin >= thsim] <- 1
  simBin[simBin < thsim] <- NA
  
  # ------------------------------------------------------------
  # Ergebnisraster berechnen
  # ------------------------------------------------------------
  
  # Vereinigungsfläche T
  Traster <- overlay(
    simBin,
    obsBin,
    fun = function(a, b) {
      result <- a == 1 | b == 1
      result[result == 0] <- NA
      return(result)
    }
  )
  
  # Korrekt simulierte Fläche X
  Xraster <- overlay(
    simBin,
    obsBin,
    fun = function(a, b) {
      result <- a == 1 & b == 1
      result[result == 0] <- NA
      return(result)
    }
  )
  
  # Unterschätzte Fläche U
  Uraster <- overlay(
    simBin,
    obsBin,
    fun = function(a, b) {
      result <- is.na(a) & b == 1
      result[result == 0] <- NA
      return(result)
    }
  )
  
  # Überschätzte Fläche O
  Oraster <- overlay(
    simBin,
    obsBin,
    fun = function(a, b) {
      result <- a == 1 & is.na(b)
      result[result == 0] <- NA
      return(result)
    }
  )
  
  # ------------------------------------------------------------
  # Flächenwerte berechnen
  # ------------------------------------------------------------
  
  Tval <- sum(
    Traster[],
    na.rm = TRUE
  )
  
  Xval <- sum(
    Xraster[],
    na.rm = TRUE
  )
  
  Uval <- sum(
    Uraster[],
    na.rm = TRUE
  )
  
  Oval <- sum(
    Oraster[],
    na.rm = TRUE
  )
  
  Aval <- sum(
    obsBin[],
    na.rm = TRUE
  )
  
  Ahvl <- sum(
    simBin[],
    na.rm = TRUE
  )
  
  # ------------------------------------------------------------
  # Prüfen, ob eine gültige Fläche vorhanden ist
  # ------------------------------------------------------------
  
  if (Tval == 0) {
    stop(
      "Die Vereinigungsfläche T ist leer. ",
      "Prüfen Sie die Schwellenwerte thobs und thsim."
    )
  }
  
  if (Aval == 0) {
    stop(
      "Die beobachtete Fläche ist leer. ",
      "Prüfen Sie thobs und das Referenzraster."
    )
  }
  
  if (Ahvl == 0) {
    stop(
      "Die simulierte Fläche ist leer. ",
      "Prüfen Sie thsim und das Simulationsraster."
    )
  }
  
  # ------------------------------------------------------------
  # Omega_T-Komponenten berechnen
  # ------------------------------------------------------------
  
  alpha <- Xval / Tval
  beta  <- Uval / Tval
  gamma <- Oval / Tval
  
  # Omega_T nach Gleichung (7)
  omegaT <- alpha - beta - gamma
  
  # ------------------------------------------------------------
  # Zusätzliche Kennwerte berechnen
  # ------------------------------------------------------------
  
  Omega <- (
    Xval / Aval -
      Uval / Aval -
      Oval / Aval
  )
  
  phi <- sqrt(
    Xval / Tval
  )
  
  e2 <- sqrt(
    Xval / Aval
  )
  
  Ia <- (
    Xval / Aval +
      Xval / Ahvl
  ) / 2
  
  diffAh_A <- Ahvl - Aval
  U_A <- Uval / Aval
  O_A <- Oval / Aval
  quotAh_A <- Ahvl / Aval
  quotX_a <- Xval / Aval
  
  # ------------------------------------------------------------
  # Rückgabe aller Kennwerte
  # ------------------------------------------------------------
  
  if (all) {
    
    errTab <- cbind(
      alpha,
      beta,
      gamma,
      omegaT,
      Omega,
      phi,
      e2,
      Ia,
      diffAh_A,
      U_A,
      O_A,
      quotAh_A,
      quotX_a
    )
    
    colnames(errTab) <- c(
      "alphaT",
      "betaT",
      "gammaT",
      "OmegaT",
      "Omega",
      "phi",
      "e2",
      "Ia",
      "Asim_minus_Aobs",
      "U_div_Aobs",
      "O_div_Aobs",
      "Asim_div_Aobs",
      "X_div_Aobs"
    )
    
    returnList <- list(
      T = Traster,
      X = Xraster,
      U = Uraster,
      O = Oraster,
      ErrorTable = errTab
    )
    
  } else {
    
    # Wichtig:
    # Hier wurde omega durch omegaT ersetzt.
    omegavector <- c(
      alpha = alpha,
      beta = beta,
      gamma = gamma,
      omega = omegaT
    )
    
    returnList <- list(
      T = Traster,
      X = Xraster,
      U = Uraster,
      O = Oraster,
      Omega = omegavector
    )
  }
  
  return(returnList)
}