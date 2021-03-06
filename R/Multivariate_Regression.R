NNS.M.reg <- function (X_n, Y, factor.2.dummy = FALSE, order = NULL, stn = NULL, n.best = NULL, type = NULL, point.est = NULL, plot = FALSE, residual.plot = TRUE, location = NULL, noise.reduction = 'off', dist = "L2", return.values = FALSE, plot.regions = FALSE, ncores=ncores){


  ### For Multiple regressions
  ###  Turn each column into numeric values
  original.IVs <- X_n
  original.DV <- Y
  n <- ncol(original.IVs)

  if(is.null(ncol(X_n))){
    X_n <- t(t(X_n))
  }

  if(is.null(names(Y))){
    y.label <- "Y"
  } else {
    y.label <- names(Y)
  }

  np <- nrow(point.est)

  if(is.null(np) & !is.null(point.est)){
    point.est <- t(point.est)
  } else {
    point.est <- point.est
  }


  if(!is.null(point.est)){
    if(ncol(point.est) != n){
      stop("Please ensure 'point.est' is of compatible dimensions to 'x'")
    }
  }

  original.matrix <- cbind.data.frame(original.IVs, original.DV)

  minimums <- apply(original.IVs, 2, min)
  maximums <- apply(original.IVs, 2, max)

  reg.points <- list()
  sections <- list()

  ###  Regression Point Matrix
  if(is.numeric(order) | is.null(order)){

    reg.points <- apply(original.IVs,2, function(b) NNS.reg(b, original.DV, factor.2.dummy = FALSE, order = order, stn = stn, type = type, noise.reduction = noise.reduction, plot = FALSE, multivariate.call = TRUE)$x)

    if(length(unique(sapply(reg.points, length))) != 1){
      reg.points.matrix <- do.call('cbind', lapply(reg.points, `length<-`, max(lengths(reg.points))))
    } else {
      reg.points.matrix <- reg.points
    }
  } else {
    reg.points.matrix <- original.IVs
  }


  ### If regression points are error (not likely)...
  if(length(reg.points.matrix[ , 1]) == 0){
    for(i in 1 : n){
      part.map <- NNS.part(original.IVs[ , i], original.DV, order = order, type = type, noise.reduction = noise.reduction, obs.req = 0)
      dep <- NNS.dep(original.IVs[ , i], original.DV, order = 3)$Dependence
      if(dep > stn){
        reg.points[[i]] <- NNS.part(original.IVs[ , i], original.DV, order = round(dep * max(nchar(part.map$df$quadrant))), type = type, noise.reduction = 'off', obs.req = 0)$regression.points$x
      } else {
        reg.points[[i]] <- NNS.part(original.IVs[ , i], original.DV, order = round(dep * max(nchar(part.map$df$quadrant))), noise.reduction = noise.reduction, type = "XONLY", obs.req = 1)$regression.points$x
      }
    }
    reg.points.matrix <- do.call('cbind', lapply(reg.points, `length<-`, max(lengths(reg.points))))
  }

  if(is.null(colnames(original.IVs))){
    colnames.list <- list()
    for(i in 1 : n){
      colnames.list[i] <- paste0("X", i)
    }
    colnames(reg.points.matrix) <- as.character(colnames.list)
  }

  if(is.numeric(order) | is.null(order)){
      reg.points.matrix <- unique(reg.points.matrix)
  }

  ### Find intervals in regression points for each variable, use left.open T and F for endpoints.
  NNS.ID <- list()

  for(j in 1:n){
    sorted.reg.points <- sort(reg.points.matrix[ , j])
    sorted.reg.points <- sorted.reg.points[!is.na(sorted.reg.points)]

    NNS.ID[[j]] <- findInterval(original.IVs[ , j], sorted.reg.points, left.open = FALSE)
  }


  NNS.ID <- do.call(cbind,NNS.ID)

  ### Create unique identifier of each observation's interval
  NNS.ID <- gsub(do.call(paste, as.data.frame(NNS.ID)), pattern = " ", replacement = ".")


  ### Match y to unique identifier
  obs <- c(1 : length(Y))

  mean.by.id.matrix <- data.table(original.IVs, original.DV, NNS.ID, obs)

  setkey(mean.by.id.matrix, 'NNS.ID', 'obs')
  if(is.numeric(order) | is.null(order)){
      if(noise.reduction == 'off'){
          mean.by.id.matrix = mean.by.id.matrix[ , y.hat := gravity(original.DV), by = 'NNS.ID']
      }
      if(noise.reduction == 'mean'){
          mean.by.id.matrix = mean.by.id.matrix[ , y.hat := mean(original.DV), by = 'NNS.ID']
      }
      if(noise.reduction == 'median'){
          mean.by.id.matrix = mean.by.id.matrix[ , y.hat := median(original.DV), by = 'NNS.ID']
      }
      if(noise.reduction == 'mode' & is.null(type)){
          mean.by.id.matrix = mean.by.id.matrix[ , y.hat := mode(original.DV), by = 'NNS.ID']
      }
      if(noise.reduction == 'mode' & !is.null(type)){
          mean.by.id.matrix = mean.by.id.matrix[ , y.hat := mode_class(original.DV), by = 'NNS.ID']
      }
  } else {
      mean.by.id.matrix = mean.by.id.matrix[ , y.hat := original.DV, by = 'NNS.ID']
  }

  y.identifier <- mean.by.id.matrix[ , NNS.ID]


  ###Order y.hat to order of original Y
  resid.plot <- mean.by.id.matrix[]
  setkey(resid.plot, 'obs')
  y.hat <- mean.by.id.matrix[ , .(y.hat)]
  if(!is.null(type)){
      y.hat <- round(y.hat)
  }


  fitted.matrix <- data.table(original.IVs, y = original.DV, y.hat, mean.by.id.matrix[ , .(NNS.ID)])

  setkey(mean.by.id.matrix, 'NNS.ID')
  REGRESSION.POINT.MATRIX <- mean.by.id.matrix[ , obs := NULL]


  if(is.numeric(order) | is.null(order)){
    if(noise.reduction == 'off'){
      REGRESSION.POINT.MATRIX <- REGRESSION.POINT.MATRIX[ , lapply(.SD, function(z) as.numeric(gravity(z))), by = NNS.ID]
    }
    if(noise.reduction == 'mean'){
      REGRESSION.POINT.MATRIX <- REGRESSION.POINT.MATRIX[ , lapply(.SD, function(z) as.numeric(mean(z))), by = NNS.ID]
    }
    if(noise.reduction == 'median'){
      REGRESSION.POINT.MATRIX <- REGRESSION.POINT.MATRIX[, lapply(.SD, function(z) as.numeric(median(z))), by = NNS.ID]
    }
    if(noise.reduction == 'mode' & is.null(type)){
      REGRESSION.POINT.MATRIX <- REGRESSION.POINT.MATRIX[, lapply(.SD, function(z) as.numeric(mode(z))), by = NNS.ID]
    }
    if(noise.reduction == 'mode' & !is.null(type)){
      REGRESSION.POINT.MATRIX <- REGRESSION.POINT.MATRIX[, lapply(.SD, function(z) as.numeric(mode_class(z))), by = NNS.ID]
    }
  }

  REGRESSION.POINT.MATRIX <- REGRESSION.POINT.MATRIX[ , NNS.ID := NULL]
  REGRESSION.POINT.MATRIX <- REGRESSION.POINT.MATRIX[ , original.DV := NULL]


  if(!is.numeric(n.best)){
    n.best <- REGRESSION.POINT.MATRIX[ , .N]
  } else {
    n.best <- n.best
  }

  ### Point estimates
  if(!is.null(point.est)){

    ### Point estimates
    central.points <- apply(original.IVs, 2, function(x) mean(c(mean(x), median(x), mode(x), mean(c(max(x), min(x))))))

    predict.fit <- numeric()
    predict.fit.iter <- list()

    if(is.null(np)){
      l <- length(point.est)

      if(sum(point.est >= minimums & point.est <= maximums) == l){

        predict.fit <- NNS.distance(rpm = REGRESSION.POINT.MATRIX, dist.estimate = point.est, type = dist, k = n.best)
      } else {
        boundary.points <- pmin(pmax(point.est, minimums), maximums)
        mid.points <- (boundary.points + central.points) / 2
        mid.points_2 <- (boundary.points + mid.points) / 2
        last.known.distance_1 <- sqrt(sum((boundary.points - central.points) ^ 2))
        last.known.distance_2 <- sqrt(sum((boundary.points - mid.points) ^ 2))
        last.known.distance_3 <- sqrt(sum((boundary.points - mid.points_2) ^ 2))

        boundary.estimates <- NNS.distance(rpm = REGRESSION.POINT.MATRIX, dist.estimate = boundary.points, type = dist, k = n.best)

        last.known.gradient_1 <- (boundary.estimates - NNS.distance(rpm = REGRESSION.POINT.MATRIX, dist.estimate = central.points, type = dist, k = n.best)) / last.known.distance_1
        last.known.gradient_2 <- (boundary.estimates - NNS.distance(rpm = REGRESSION.POINT.MATRIX, dist.estimate = mid.points, type = dist, k = n.best)) / last.known.distance_2
        last.known.gradient_3 <- (boundary.estimates - NNS.distance(rpm = REGRESSION.POINT.MATRIX, dist.estimate = mid.points_2, type = dist, k = n.best)) / last.known.distance_3

        last.known.gradient <- (last.known.gradient_1 + 2*last.known.gradient_2 + 4*last.known.gradient_3) / 7

        last.distance <- sqrt(sum((point.est - boundary.points) ^ 2))

        predict.fit <- last.distance * last.known.gradient + boundary.estimates
      }
    }

    if(!is.null(np)){


      lows <- logical()
      highs <- logical()
      outsiders <- numeric()
      DISTANCES <- list()

      ### PARALLEL

      if (is.null(ncores)) {
        num_cores <- as.integer(detectCores() / 2) - 1
      } else {
        num_cores <- ncores
      }

      if(num_cores>1){
        cl <- makeCluster(num_cores)
        registerDoParallel(cl)
      } else { cl <- NULL }

      DISTANCES <- foreach(i = 1:nrow(point.est),.packages = c("NNS","data.table", "dtw"))%dopar%{
        NNS.distance(rpm = REGRESSION.POINT.MATRIX, dist.estimate = point.est[i,],
                     type = dist, k = n.best)[1]
      }


      if(!is.null(cl)){
        stopCluster(cl)
        registerDoSEQ()
      }

      DISTANCES <- unlist(DISTANCES)

      lows <- do.call(pmin,as.data.frame(t(point.est))) < minimums
      highs <- do.call(pmax,as.data.frame(t(point.est))) > maximums

      outsiders <- lows + highs

      outsiders[is.na(outsiders)] <- 0

      if(sum(outsiders)>0){
        outside.columns <- numeric()
        outside.columns <- which(outsiders>0)

        # Find rows from those columns
        outside.index <- list()
        outside.index <- foreach(i = 1:length(outside.columns))%dopar%{
          which(point.est[ , outside.columns[i]] > maximums[outside.columns[i]] |
                              point.est[,outside.columns[i]] < minimums[outside.columns[i]])
        }

        outside.index <- unique(unlist(outside.index))

        for(i in outside.index){
          outside.points <- point.est[i,]
          boundary.points <- pmin(pmax(outside.points, minimums), maximums)
          mid.points <- (boundary.points + central.points) / 2
          mid.points_2 <- (boundary.points + mid.points) / 2
          last.known.distance_1 <- sqrt(sum((boundary.points - central.points) ^ 2))
          last.known.distance_2 <- sqrt(sum((boundary.points - mid.points) ^ 2))
          last.known.distance_3 <- sqrt(sum((boundary.points - mid.points_2) ^ 2))

          if(dist=="DTW"){
            dist <- "L2"
          }

          boundary.estimates <- NNS.distance(rpm = REGRESSION.POINT.MATRIX,
                            dist.estimate = boundary.points,
                            type = dist, k = n.best)

          last.known.gradient_1 <- (boundary.estimates - NNS.distance(rpm = REGRESSION.POINT.MATRIX, dist.estimate = central.points, type = dist, k = n.best)) / last.known.distance_1
          last.known.gradient_2 <- (boundary.estimates - NNS.distance(rpm = REGRESSION.POINT.MATRIX, dist.estimate = mid.points, type = dist, k = n.best)) / last.known.distance_2
          last.known.gradient_3 <- (boundary.estimates - NNS.distance(rpm = REGRESSION.POINT.MATRIX, dist.estimate = mid.points_2, type = dist, k = n.best)) / last.known.distance_3

          last.known.gradient <- (last.known.gradient_1 + 2*last.known.gradient_2 + 4*last.known.gradient_3) / 7

          last.distance <- sqrt(sum((outside.points - boundary.points) ^ 2))


          DISTANCES[i] <- last.distance * last.known.gradient + boundary.estimates
        }
      }

      predict.fit <- DISTANCES



    }

  } else {
    predict.fit <- NULL
  } # is.null point.est




  R2 <- (sum((y.hat - mean(original.DV)) * (original.DV - mean(original.DV))) ^ 2) / (sum((original.DV - mean(original.DV)) ^ 2) * sum((y.hat - mean(original.DV)) ^ 2))

  fitted.matrix$residuals <- fitted.matrix$y.hat - fitted.matrix$y

  ### 3d plot
  if(plot && n == 2){
    region.1 <- mean.by.id.matrix[[1]]
    region.2 <- mean.by.id.matrix[[2]]
    region.3 <- mean.by.id.matrix[ , y.hat]

    plot3d(x = original.IVs[ , 1], y = original.IVs[ , 2], z = original.DV, box = FALSE, size = 3, col='steelblue', xlab = colnames(reg.points.matrix)[1], ylab = colnames(reg.points.matrix)[2], zlab = y.label )

    if(plot.regions){
      region.matrix <- data.table(original.IVs, original.DV, NNS.ID)
      region.matrix[ , `:=` (min.x1 = min(.SD), max.x1 = max(.SD)), by = NNS.ID, .SDcols = 1]
      region.matrix[ , `:=` (min.x2 = min(.SD), max.x2 = max(.SD)), by = NNS.ID, .SDcols = 2]
      if(noise.reduction == 'off'){
        region.matrix[ , `:=` (y.hat = gravity(original.DV)), by = NNS.ID]
      }
      if(noise.reduction == 'mean'){
        region.matrix[ , `:=` (y.hat = mean(original.DV)), by = NNS.ID]
      }
      if(noise.reduction == 'median'){
        region.matrix[ , `:=` (y.hat = median(original.DV)), by = NNS.ID]
      }
      if(noise.reduction=='mode'){
        region.matrix[ , `:=` (y.hat = mode(original.DV)), by = NNS.ID]
      }

      setkey(region.matrix, NNS.ID, min.x1, max.x1, min.x2, max.x2)
      region.matrix[ ,{
        quads3d(x = .(min.x1[1], min.x1[1], max.x1[1], max.x1[1]),
                y = .(min.x2[1], max.x2[1], max.x2[1], min.x2[1]),
                z = .(y.hat[1], y.hat[1], y.hat[1], y.hat[1]), col='pink', alpha=1)
        if(identical(min.x1[1], max.x1[1]) | identical(min.x2[1], max.x2[1])){
          segments3d(x = .(min.x1[1], max.x1[1]),
                     y = .(min.x2[1], max.x2[1]),
                     z = .(y.hat[1], y.hat[1]), col = 'pink', alpha = 1)
        }
      }
      , by = NNS.ID]
    }#plot.regions = T


    points3d(x = as.numeric(unlist(REGRESSION.POINT.MATRIX[ , .SD, .SDcols = 1])), y = as.numeric(unlist(REGRESSION.POINT.MATRIX[ , .SD, .SDcols = 2])), z = as.numeric(unlist(REGRESSION.POINT.MATRIX[ , .SD, .SDcols = 3])), col = 'red', size = 5)
    if(!is.null(point.est)){
      if(is.null(np)){
        points3d(x = point.est[1], y = point.est[2], z = predict.fit, col = 'green', size = 5)
      } else {
        points3d(x = point.est[,1], y = point.est[,2], z = predict.fit, col = 'green', size = 5)
      }
    }
  }

  ### Residual plot
  if(residual.plot){
    resids <- cbind(original.DV, y.hat)
    r2.leg <- bquote(bold(R ^ 2 == .(format(R2, digits = 4))))
    matplot(resids, type = 'l', xlab = "Index", ylab = expression(paste("y (black)   ", hat(y), " (red)")), cex.lab = 1.5, mgp = c(2, .5, 0))

    title(main = paste0("NNS Order = multiple"), cex.main = 2)
    legend(location, legend = r2.leg, bty = 'n')
  }


  rhs.partitions <- data.table(reg.points.matrix)

  if(!is.null(type)){
      fitted.matrix$y.hat <- round(fitted.matrix$y.hat)
      if(!is.null(predict.fit)){
          predict.fit <- round(predict.fit)
      }
  }

  ### Return Values
  if(return.values){

    return(list(R2 = R2,
                rhs.partitions = rhs.partitions,
                RPM = REGRESSION.POINT.MATRIX[] ,
                Point.est = predict.fit,
                Fitted.xy = fitted.matrix[]))
  } else {
    invisible(list(R2 = R2,
                   rhs.partitions = rhs.partitions,
                   RPM = REGRESSION.POINT.MATRIX[],
                   Point.est = predict.fit,
                   Fitted.xy = fitted.matrix[]))
  }

}
