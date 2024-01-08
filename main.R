library(petroGeo2) # Trocar para o FUSE 

source("./app/utils.R")

# Loading data
train_data <- read.csv("./app/train_data.csv")

# Scaling the data
train_data <- scaleFeatures(train_data)

# Model settings
geo.coords <- as.matrix(train_data$data[,1:3]) # Geographic Coords
sismic.coords <- as.matrix(train_data$data[,c("rho","vp","vs")]) # Sismic Coords
sismic.coords <- sismic.coords + rnorm(prod(dim(sismic.coords)),sd = 1e-04)
Xmat <- as.matrix(cbind(1,train_data$data[,c("rho","vp","vs")])) # Design matrix

MODEL_TYPE = "sismic"
K <- 10

# Build & compile the model
model <- buildModel(type = MODEL_TYPE, k = K)
Rmodel <- model$Rmodel
constants <- model$constants

conf <- configureMCMC(Rmodel)
if(MODEL_TYPE == "mixture") conf$addMonitors('lambda')
Rmcmc <- buildMCMC(conf) #Build the MCM
Cmodel <- compileNimble(Rmodel) # Compile the model in C++
Cmcmc <- compileNimble(Rmcmc, project = Rmodel) # Compile the MCMC in C++

N_ITER <- 200L # MCMC total iterations
N_BURN_IN <- 50L # Burn-in phase
LAG <- 1L # Chain lag

cat("Starting MCMC sampling...\n")
Sys.sleep(1.5)

t <- Sys.time()
samples <- runMCMC(Cmcmc, niter = N_ITER, nburnin = N_BURN_IN, thin = LAG)
print(Sys.time() - t)

# Saving the posterior samples
saveRDS(samples, file = "/app/posteriorSamples.rds")

# Predict
pred_data <- read.csv("./app/predict_data.csv")
pred_data <- scalePredFeatures(pred_data, scale_info = train_data$scaling)

pred.geo.coords <- as.matrix(pred_data[,1:3]) # Geographic Coords
pred.sismic.coords <- as.matrix(pred_data[,c("rho","vp","vs")]) # Sismic Coords
pred.sismic.coords <- pred.sismic.coords + rnorm(prod(dim(pred.sismic.coords)),sd = 1e-04)
Xmat_pred <- as.matrix(cbind(1,pred_data[,c("rho","vp","vs")])) # Design matrix for the prediction locations

cat("Starting prediction...\n")
Sys.sleep(1.5)
predLocations <- predModel(type = MODEL_TYPE)

# Saving the posterior predictions
#saveRDS(pred, "./output/posteriorPredictions.rds")

# Posterior statistics
posteriorStat <- list("media" = apply(predLocations$pred$pred,2,mean),
                      "q_275" = apply(predLocations$pred$pred, 2, function(x) quantile(x,probs = 0.0275)),
                      "q_50" = apply(predLocations$pred$pred, 2, function(x) quantile(x,probs = 0.5)),
                      "q_975" = apply(predLocations$pred$pred, 2, function(x) quantile(x,probs = 0.975)))

saveRDS(posteriorStat, "./output/posteriorStatistics.rds") # Saving the posterior predictions

print("DONE")