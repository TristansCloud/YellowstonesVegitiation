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
n=203
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

dense_output <- layer_concatenate(c(highres.crop.model,lowres.model)) %>% 
  layer_conv_2d(kernel_size = c(1, 1), filter = 32,
                activation = "relu", padding = "valid") %>% 
  layer_flatten() %>% #might need this to have dense layers
  layer_dropout(rate = 0.3) %>% 
  layer_dense(units = 500, activation = 'relu') %>%
  layer_dropout(rate = 0.27) %>% 
  layer_dense(units = 2601, activation = 'relu') %>% 
  layer_reshape(target_shape = c(51,51)  ,name = 'dense_output')

#for only high res image
cnn_output<- highres.crop.input %>%
  layer_conv_2d(kernel_size = c(3, 3), strides = 1, filter = 16,
                              activation = "relu", padding = "same",
                              data_format = "channels_last") %>% 
  layer_batch_normalization() %>% 
  layer_conv_2d(kernel_size = c(3, 3), filter = 8,
                activation = "relu", padding = "same")%>% 
  layer_batch_normalization() %>%
  layer_conv_2d(kernel_size = c(1,1),filters = 1,
                activation = "relu",name = "cnn_output")
  added_highres<-layer_add(c(highres.crop.input,cnn_output),name = "added_highres")


  layer_conv_2d_transpose(kernel_size = c(2,2),filters = 16,
                          activation = "relu") %>% 
  layer_batch_normalization() %>%
  layer_conv_2d_transpose(kernel_size = c(3,1),filters = 8,
                          strides = c(1,1), activation = "relu") %>% 
  layer_conv_2d_transpose(kernel_size = c(1,3),filters = 8,
                          strides = c(1,1), activation = "relu") %>%  
  layer_batch_normalization() %>% 
   

  #layer_zero_padding_2d(padding = c(2,2)) %>% 

  
  layer_batch_normalization() %>% 
  layer_conv_2d(kernel_size = c(3,3),filters = 8,
                strides = 2,padding = "same", activation = "relu")

# transposed convolution
transp_highres<-layer_conv_2d_transpose() # larger stride = larger output

### Also try to create a deconvolution approach to prediction
  
model1<-keras_model(
  inputs = c(highres.crop.input,lowres.input),
  outputs = dense_output
)
summary(model1)

model2<-keras_model(
  inputs = c(highres.crop.input),
  outputs = added_highres
)
summary(model2)
evaluate(mymodel2)

## Compile model ##

model1 %>% compile(loss = 'mse',
                  optimizer = 'adam',
                  metrics = 'Accuracy') # mae = mean absolute error

optimizer_adam(lr = 0.001, beta_1 = 0.9, beta_2 = 0.999,
               epsilon = NULL, decay = 0, amsgrad = FALSE, clipnorm = NULL,
               clipvalue = NULL)
callback_reduce_lr_on_plateau(monitor = "val_loss", factor = 0.1,
                              patience = 10, verbose = 0, mode = c("auto"),
                              min_delta = 1e-04, cooldown = 0, min_lr = 0)
model2 %>% compile(loss = 'mse',
                   optimizer = 'Nadam',
                   metric = "mse")

# custom metric #
metric_rsquare <- custom_metric("metric_rsquare", function(y_true, y_pred) {
  (cor(y_true, y_pred)^2)
})



## Fit model ##

mymodel<-model1 %>% fit(
  x = list(highres.crop_input = highres.crop.tensor, lowres_input = lowres.tensor),
  y = list(dense_output = ndvi.tensor),
  epochs = 30,
  batch_size = 32,
  validation_split = 0.15)

mymodel2<-model2 %>% fit(
  x = list(highres.crop_input = highres.crop.tensor),
  y = list(added_highres = ndvi.tensor),
  epochs = 30,
  batch_size = 32,
  validation_split = 0.05
)


# Predict new data

pred <- mymodel2 %>% predict(valdata)
  

# Saving the model
save_model_hdf5()
load_model_hdf5()
  
  