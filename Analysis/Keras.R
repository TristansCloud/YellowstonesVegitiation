# Starting keras script
library(keras)
library(raster)
library(abind)
#install.packages("cloudml") # if you need to use GCP

# Data
load("ndvi.RData")
load("highrescrop.RData")
load("lowres.RData")

# Add channel dimension to array

channel<-1
ndvi.tensor.tmp<-array(rep(ndvi.array,length(channel)),c(dim(ndvi.array),length(channel)))
lowres.tensor.tmp<-array(rep(lowres.array,length(channel)),c(dim(lowres.array),length(channel)))
highres.crop.tensor.tmp<-array(rep(highres.crop.array,length(channel)),c(dim(highres.crop.array),length(channel)))
rm(highres.crop.array,lowres.array,ndvi.array)
ndvi.tensor <- aperm(ndvi.tensor.tmp, c(3,1,2,4))
lowres.tensor <- aperm(lowres.tensor.tmp, c(3,1,2,4))
highres.crop.tensor <- aperm(highres.crop.tensor.tmp, c(3,1,2,4))
rm(ndvi.tensor.tmp,lowres.tensor.tmp,highres.crop.tensor.tmp,channel)


#Check rasters are layered properly
extent<-matrix(c(4/9, 4/9,
               4/9, 5/9,
               5/9, 5/9,
               5/9, 4/9,
               4/9, 4/9),
             ncol = 2, byrow = TRUE)
n=1555
plot(raster(ndvi.tensor[n,,,]))
plot(raster(highres.crop.tensor[n,,,]))
plot(raster(lowres.tensor[n,,,]),ext=extent)
plot(raster(lowres.tensor[n,,,]))

## Start of model ##
lowres.input<-layer_input(shape = c(153,153,1),name = "lowres_input")
highres.crop.input<-layer_input(shape = c(51,51,1),name = "highres.crop_input")

highres.crop.model<- highres.crop.input %>% 
  layer_conv_2d(kernel_size = c(3, 3), strides = 3, filter = 32,
                activation = "relu", padding = "valid",
                data_format = "channels_last") %>% 
  layer_conv_2d(kernel_size = c(2, 2), filter = 32,
                activation = "relu", padding = "valid") 
  #layer_batch_normalization() #axis=chanDim

lowres.model<- lowres.input %>%   
  layer_conv_2d(kernel_size = c(3, 3), filter = 32, strides = 3,
                activation = "relu", padding = "valid") %>%
  layer_conv_2d(kernel_size = c(3, 3), filter = 64,
                activation = "relu", padding = "same") %>%
  layer_max_pooling_2d(pool_size = 3) %>%
  layer_dropout(rate = 0.2) %>%
  layer_conv_2d(kernel_size = c(2, 2), filter = 32,
                activation = "relu", padding = "valid") 

  #layer_conv_2d(kernel_size = c(3, 3), filter = 64,
  #              activation = "relu", padding = "valid")
  #layer_batch_normalization() #axis=chanDim

main_output <- layer_concatenate(c(highres.crop.model,lowres.model)) %>%  
  layer_flatten() %>% #might need this to have dense layers
  layer_dense(units = 1000, activation = 'relu') %>%
  layer_dropout(rate = 0.27) %>% 
  layer_dense(units = 2601, activation = 'relu', name = 'main_output')

### Also try to create a deconvolution approach to prediction
  
model1<-keras_model(
  inputs = c(highres.crop.input,lowres.input),
  outputs = main_output
)


## Compile model ##

model %>% compile(loss = 'mse',
                  optimizer = '',
                  metrics = 'mae') # mae = mean absolute error
  #for a two input model
model %>% compile(
  optimizer = 'rmsprop',
  loss = list(main_output = 'binary_crossentropy', aux_output = 'binary_crossentropy'),
  loss_weights = list(main_output = 1.0, aux_output = 0.2)
)


## Fit model ##

  # for two inputs
mymodel<-model %>% fit(
  x = list(main_input = headline_data, aux_input = additional_data),
  y = list(main_output = labels, aux_output = labels),
  epochs = 50,
  batch_size = 32,
  validation_split = 0.15)



# Predict new data

pred <- model %>% predict(valdata)
  

# Saving the model
save_model_hdf5()
load_model_hdf5()
  
  