library(keras)
setwd("/Users/triskos/RProjs/GISneuralnet")

load("data/sspr.ndvi.tensor.RData")
load("data/sspr.highdem.tensor.RData")
load("data/yspr.ndvi.tensor.RData")
load("data/yspr.highdem.tensor.RData")


#start
highres.crop.input<-layer_input(shape = c(51,51,1))

residuals1<-highres.crop.input %>%
  layer_cropping_2d(cropping = list(c(3,2),c(3,2))) %>% 
  layer_conv_2d(kernel_size = c(3, 3), filter = 8,
                activation = "relu", padding = "valid") 
max1<-residuals1%>% 
  layer_max_pooling_2d(pool_size = 2, strides = 2)

residuals2<-max1 %>% 
  layer_conv_2d(kernel_size = c(3, 3), filter = 16,
                activation = "relu", padding = "valid") 
max2<-residuals2 %>% 
  layer_max_pooling_2d(pool_size = 2, strides = 2)
  
residuals3<-max2 %>% 
  layer_conv_2d(kernel_size = c(3, 3), filter = 32,
                activation = "relu", padding = "valid")

upsample1<-residuals3 %>% 
  layer_conv_2d_transpose(kernel_size = c(2, 2), filter =16,
                          strides = 2, padding = "valid")

crop1<-residuals2 %>% 
  layer_cropping_2d(cropping = 2)

concat1<- layer_add(list(upsample1, crop1)) %>% 
  layer_conv_2d(kernel_size = c(3, 3), filter = 16,
                activation = "relu", padding = "valid") %>% 
  layer_conv_2d_transpose(kernel_size = c(2, 2), filter = 8,
                strides = 2, padding = "valid")

crop2<-residuals1 %>% 
  layer_cropping_2d(cropping = 8)

concat2<-layer_add(list(concat1, crop2)) %>% 
  layer_conv_2d(kernel_size = c(2, 2), filter = 8,
              activation = "relu", padding = "valid") %>% 
  layer_conv_2d(kernel_size = c(1, 1), filter = 1,
                activation = "linear")

train_label<-sspr.ndvi.tensor %>% 
  layer_cropping_2d(cropping = 12, name = "train_label")
val_label <- yspr.ndvi.tensor %>% 
  layer_cropping_2d(cropping = 12, name = "val_label")

residual_model<-keras_model(
  inputs = highres.crop.input,
  outputs = concat2
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
  x = sspr.highdem.tensor,
  y = train_label,
  epochs = 1,
  #batch_size = 32,
  steps_per_epoch = 500
  #validation_data=list(yspr.highdem.tensor,val_label),
  #callbacks = list(constant_save,bestmod),
  #shuffle = TRUE 
)

setwd("/Users/triskos/git-directory/YellowstonesVegitiation")
save_model_hdf5(residual_model,"residual-learning-moretrained.h5")
