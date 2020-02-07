library(keras)


load("sspr.ndvi.tensor.RData")
load("sspr.highdem.tensor.RData")
load("yspr.ndvi.tensor.RData")
load("yspr.highdem.tensor.RData")


#start
highres.crop.input<-layer_input(shape = c(51,51,1),name = "highres.crop_input")

residuals<-highres.crop.input %>%
  layer_conv_2d(kernel_size = c(3, 3), filter = 64,
                activation = "relu", padding = "same") %>% 
  layer_conv_2d(kernel_size = c(3, 3), filter = 64,
                activation = "relu", padding = "same") %>% 
  layer_conv_2d(kernel_size = c(3, 3), filter = 64,
                activation = "relu", padding = "same") %>% 
  layer_conv_2d(kernel_size = c(3, 3), filter = 64,
                activation = "relu", padding = "same") %>% 
  layer_conv_2d(kernel_size = c(3, 3), filter = 1,
                activation = "linear", padding = "same")


prediction<-layer_add(list(residuals,highres.crop.input))


residual_model<-keras_model(
  inputs = c(highres.crop.input),
  outputs = prediction
)
summary(residual_model)

residual_model %>% compile(loss = 'mse',
                        optimizer = 'Nadam',
                        metric = "mse")


checkpoint_path="residual-learning.ckpt"
constant_save <- callback_model_checkpoint(
  filepath = checkpoint_path,
  save_weights_only = TRUE,
  save_best_only = FALSE,
  save_freq = 5,
  period = 5,
  verbose = 0
)
best_path = "best-residual-learning.ckpt"
bestmod <- callback_model_checkpoint(
  filepath = best_path,
  save_weights_only = TRUE,
  save_best_only = TRUE,
  mode = "auto",
  verbose = 0
)



residual_model %>% fit(
  x = list(highres.crop_input = sspr.highdem.tensor),
  y = list(prediction = sspr.ndvi.tensor),
  epochs = 15,
  batch_size = 32,
  validation_data=list(list(yspr.highdem.tensor),yspr.ndvi.tensor),
  callbacks = list(constant_save,bestmod),
  shuffle = TRUE 
)

save_model_hdf5(residual_model,"residual-learning.h5")
