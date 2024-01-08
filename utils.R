## -- SCALE FEATURES -- ## 
# Scale the features and save the scale information.

scaleFeatures <- function(data) {
  data$rho <- scale(data$rho)
  data$vp <- scale(data$vp)
  data$vs <- scale(data$vs)
  
  scale_info <- list(mean = data.frame("rho" = attr(data$rho,"scaled:center"),
                                       "vp" = attr(data$vp,"scaled:center"),
                                       "vs" = attr(data$vs,"scaled:center")),
                     sd = data.frame("rho" = attr(data$rho,"scaled:scale"),
                                     "vp" = attr(data$vp,"scaled:scale"),
                                     "vs" = attr(data$vs,"scaled:scale"))
  )
  return(list(data = data,
              scaling = scale_info))
}

## -- SCALE PRED FEATURES -- ##
# Apply the scaling used in training to the predict data.
scalePredFeatures <- function(data, scale_info) {
  data$rho <- scale(data$rho, 
                    center = scale_info[[1]]["rho"],
                    scale = scale_info[[2]]["rho"])
  
  data$vp <- scale(data$vp, 
                   center = scale_info[[1]]["vp"],
                   scale = scale_info[[2]]["vp"])
  
  data$vs <- scale(data$vs, 
                   center = scale_info[[1]]["vs"],
                   scale = scale_info[[2]]["vs"])
  
  return(data)
}

append_list <- function (x, y) {
  xnames <- names(x)
  for (v in names(y)) {
    if(v %in% xnames && is.list(x[[v]]) && is.list(y[[v]])){
      x[[v]] <- append_list(x[[v]], y[[v]])
    } else{
      if(!is.null(y[[v]])){
        x[[v]] <- y[[v]]
      }
    }
  }
  return(x)
}

buildModel <- function(type,k,constants=NULL){
  if(!all(type %in% c("geo","sismic","mixture"))) stop("model type must be \"geo\", \"sismic\" or \"mixture\".")
  
  constants_base <- list(nu = 0.5, k = k,
                         eta_HP1 = 0, # media da normal
                         eta_HP2 = 1.75, # sd da normal
                         Sigma_HP1 = c(500,11.5),
                         sigma_HP1 = 10,
                         tau_HP1 = 10,
                         X_mu = Xmat, mu_HP1 = 10)
  if(is.null(constants)) constants <- constants_base
  else constants <- append_list(constants_base,constants)
    
  if(type == "geo"){
    
    constants <- constants[c("nu","k","Sigma_HP1","sigma_HP1","tau_HP1",
                             "X_mu", "mu_HP1")]
    #constants <- list(nu = 0.5, k = k,
    #                  Sigma_HP1 = 500,
    #                  sigma_HP1 = 10,
    #                  tau_HP1 = 10,
    #                  X_mu = Xmat, mu_HP1 = 10)
    
    Rmodel <- nsgpModel(likelihood = "NNGP",
                        constants = constants,
                        coords = geo.crds,
                        data = train_data$data$phi,
                        Sigma_model = "isotropic", # range
                        sigma_model = "constant",
                        tau_model = "constant",
                        mu_model = "linReg",
                        distMethod = "euclidean")
  }
  
  if(type == "sismic"){
    
    constants <- constants[c("nu","k","Sigma_HP1","sigma_HP1","tau_HP1",
                             "X_mu", "mu_HP1")]
    #constants <- list(nu = 0.5, k = k,
    #                  Sigma_HP1 = c(500,11.5),
    #                  sigma_HP1 = 10,
    #                  tau_HP1 = 10,
    #                  X_mu = Xmat, mu_HP1 = 10)
    
    Rmodel <- nsgpModel(likelihood = "NNGP",
                        constants = constants,
                        coords = sismic.coords,
                        data = train_data$data$phi,
                        Sigma_model = "isotropic", # range
                        sigma_model = "constant",
                        tau_model = "constant",
                        mu_model = "linReg",
                        distMethod = "euclidean")
  }
  
  if(type == "mixture"){
    
    constants <- constants
    #constants <- list(nu = 0.5, k = k,
    #                  eta_HP1 = 0, # media da normal
    #                  eta_HP2 = 1.75, # sd da normal
    #                  Sigma_HP1 = c(500,11.5),
    #                  sigma_HP1 = 10,
    #                  tau_HP1 = 10,
    #                  X_mu = Xmat, mu_HP1 = 10)
    
    # petroGeo (Antigo)
    Rmodel <- nsgpModel(likelihood = "NNGP",
                        constants = constants,
                        coords = geo.crds,
                        sismicCoords = sismic.coords,
                        data = train_data$data$phi,
                        NN_size = "dynamic",
                        Sigma_model = "mixture", # range
                        sigma_model = "constant",
                        tau_model = "constant",
                        mu_model = "linReg",
                        distMethod = "euclidean")
  }
  
  return(list(Rmodel = Rmodel,
              constants = constants))
}

predModel <- function(type){
  if(!all(type %in% c("geo","sismic","mixture"))) stop("model type must be \"geo\", \"sismic\" or \"mixture\".")
  
  if(type == "geo"){
    t <- Sys.time()
    pred <- nsgpPredict(model = Rmodel,
                        samples = samples,
                        coords.predict = pred.geo.coords,
                        constants = list(PX_mu = Xmat_pred),
                        distMethod = "euclidean")
    print(Sys.time() - t)
    
    predLocations <- list(pred = pred,
                          model_type = type,
                          elapsed_time = seconds_to_period((t$toc - t$tic)))
  }
  
  if(type == "sismic"){
    t <- Sys.time()
    pred <- nsgpPredict(model = Rmodel,
                        samples = samples,
                        coords.predict = pred.sismic.coords,
                        constants = list(PX_mu = Xmat_pred),
                        distMethod = "euclidean")
    print(Sys.time() - t)
    
    predLocations <- list(pred = pred,
                          model_type = type,
                          elapsed_time = seconds_to_period((t$toc - t$tic)))
  }
  
  if(type == "mixture"){
    t <- Sys.time()
    pred <- nsgpPredict(model = Rmodel,
                        samples = samples,
                        coords.predict = pred.geo.coords,
                        sismicCoords.predict = pred.sismic.coords,
                        constants = list(PX_mu = Xmat_pred),
                        distMethod = "euclidean")
    print(Sys.time() - t)
    
    predLocations <- list(pred = pred,
                          model_type = type,
                          elapsed_time = seconds_to_period((t$toc - t$tic)))
  }
  
  return(predLocations)
}

