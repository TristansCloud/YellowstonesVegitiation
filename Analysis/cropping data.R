library(raster)
library(spatial.tools)

salsummer<-stack("/mnt/nfs/data/SalmonChallis/training/2016/LC080410292016072401T1-SC20191028014713/LC080410292016072401T1-SC20191028014713.tif")
salspring<-stack("/mnt/nfs/data/SalmonChallis/training/2016/LC080410292016062201T1-SC20191028014713/LC080410292016062201T1-SC20191028014713.tif")
yelsummer<-stack("/mnt/nfs/data/Yellowstone/training/2016/LC080380292016071901T1-SC20191114202936/LC080380292016071901T1-SC20191114202936.tif")
yelspring<-stack("/mnt/nfs/data/Yellowstone/training/2016/LC080380292016061701T1-SC20191114202935/LC080380292016061701T1-SC20191114202935.tif")

# reclassifying data that is out of range of typical NDVI
rcl.ndvi<-matrix(c(-Inf,0,0,
                   10000,Inf,10000),ncol = 3,byrow = TRUE)
salsummer[[2]]<- reclassify(salsummer[[2]], rcl.ndvi)
salspring[[2]]<- reclassify(salspring[[2]], rcl.ndvi)
yelsummer[[2]]<- reclassify(yelsummer[[2]], rcl.ndvi)
yelspring[[2]]<- reclassify(yelspring[[2]], rcl.ndvi)

rcl.neigh.accum<-matrix(c(6000,Inf,6000),ncol = 3,byrow = TRUE)
salsummer[[8]]<- reclassify(salsummer[[8]], rcl.neigh.accum)
salspring[[8]]<- reclassify(salspring[[8]], rcl.neigh.accum)
yelsummer[[8]]<- reclassify(yelsummer[[8]], rcl.neigh.accum)
yelspring[[8]]<- reclassify(yelspring[[8]], rcl.neigh.accum)

# Log transform neighbor flow accumulation
salsummer[[8]]<- log2(salsummer[[8]])
salspring[[8]]<- log2(salspring[[8]])
yelsummer[[8]]<- log2(yelsummer[[8]])
yelspring[[8]]<- log2(yelspring[[8]])

# Crop rasters
salcrop<-matrix(c(-114.4245, 44.35558,
                  -114.4245, 45.13208,
                  -115.818, 45.13208,
                  -115.818, 44.35558,
                  -114.4245, 44.35558),
                ncol = 2, byrow = TRUE)
plot(salsummer[[3]],ext = salcrop)
#plot(salsummer[[3]])
salsummer.crop<-crop(salsummer,salcrop)
salspring.crop<-crop(salspring,salcrop)

yelcrop<-matrix(c(-109.7065, 44.58900, # x = 1.3935, y = 0.7765
                  -109.7065, 45.36550,
                  -111.1, 45.36550,
                  -111.1, 44.58900,
                  -109.7065, 44.58900),
                ncol = 2, byrow = TRUE)
plot(yelsummer[[3]],ext = yelcrop)
#plot(yelsummer[[3]])
yelsummer.crop<-crop(yelsummer,yelcrop)
yelspring.crop<-crop(yelspring,yelcrop)

#modify sal.crop to have same # of rows and columns as yel.crop
salsummer.crop<-modify_raster_margins(salsummer.crop, extent_delta = c(0, 0, -1, 0), value = NA) # only have to drop 1 row
salspring.crop<-modify_raster_margins(salspring.crop, extent_delta = c(0, 0, -1, 0), value = NA) # only have to drop 1 row

# Fill yellowstone aspect
plot(yelsummer.crop[[6]])
yelsummer.crop[[6]] <- reclassify(yelsummer.crop[[6]], cbind(NA, 250)) # 250 = a randomly chosen value
plot(yelsummer.crop[[6]])

plot(yelspring.crop[[6]])
yelspring.crop[[6]] <- reclassify(yelspring.crop[[6]], cbind(NA, 250)) # 250 = a randomly chosen value
plot(yelspring.crop[[6]])

# Save rasters
writepath="/mnt/nfs/Rstudio/data"
writeRaster(salsummer.crop, format="GTiff", filename=file.path(writepath,"salchallissummer",fsep="/"), options=c("INTERLEAVE=BAND","COMPRESS=NONE"), overwrite=TRUE)
writeRaster(salspring.crop, format="GTiff", filename=file.path(writepath,"salchallisspring",fsep="/"), options=c("INTERLEAVE=BAND","COMPRESS=NONE"), overwrite=TRUE)
writeRaster(yelsummer.crop, format="GTiff", filename=file.path(writepath,"yellowstonesummer",fsep="/"), options=c("INTERLEAVE=BAND","COMPRESS=NONE"), overwrite=TRUE)
writeRaster(yelspring.crop, format="GTiff", filename=file.path(writepath,"yellowstonespring",fsep="/"), options=c("INTERLEAVE=BAND","COMPRESS=NONE"), overwrite=TRUE)           


# extents for diagnosis
yel<-matrix(c(1/3, 1/3,
              1/3, 2/3,
              -114.8, 2/3,
              -114.8, 1/3,
              1/3, 1/3),
                ncol = 2, byrow = TRUE)


## Creating tensors ##

mainpath = "/mnt/nfs/data"
salpath = "SalmonChallis/tensors"
yelpath = "Yellowstone/tensors"
summer =  "summer"
spring =  "spring"

test<-as.matrix(salspring[[3]])
image(test, useRaster=TRUE, axes=FALSE)
plot(salspring[[3]])
plot(raster(test))



# create both high resolution and low resolution but larger extent rasters
# world elevation is -100 to 8900. death valley is -89m, everest is 8880m
# ndvi range is 0 to 10000

salspring<-stack("/mnt/nfs/Rstudio/data/salchallisspring.tif")
salsummer<-stack("/mnt/nfs/Rstudio/data/salchallissummer.tif")
yelspring<-stack("/mnt/nfs/Rstudio/data/yellowstonespring.tif")
yelsummer<-stack("/mnt/nfs/Rstudio/data/yellowstonesummer.tif")

## SALSPRING ###
sspr<-salspring[[2:3]]
sspr.crop<-modify_raster_margins(sspr,extent_delta = c(0,-20,0,-25)) #target output = 2856 x 5151
sspr.crop
rm(sspr)

sspr.crop[[1]]<-sspr.crop[[1]]/10000
sspr.crop[[2]]<-(sspr.crop[[2]]+100)/9000 # dem from anywhere in the world can be used

sspr.lowrezdem<-raster::aggregate(sspr.crop[[2]],fact=3) # fact = 3 reduces resolution to 1/3 original

## YELSPRING ##
yspr<-yelspring[[2:3]]
yspr.crop<-modify_raster_margins(yspr,extent_delta = c(0,-20,0,-25)) #target output = 2856 x 5151
yspr.crop
rm(yspr)

yspr.crop[[1]]<-yspr.crop[[1]]/10000
yspr.crop[[2]]<-(yspr.crop[[2]]+100)/9000 # dem from anywhere in the world can be used
yspr.lowrezdem<-raster::aggregate(yspr.crop[[2]],fact=3)

## Creating tensors ##
Area="Yellowstone"
season="tensors/spring"
tens.path=file.path("/mnt/nfs/data",Area,season,fsep = "/")
# parameters, everything must be a multiple of the raster::aggregate fact, here fact = 3.
totalrows = 48 
totalcols = 93
ndvi.buffer = 204
dem.buffer = 153
high.step = 51
low.step = (high.step/3)
width.dem = 153
height.dem = 153
width.ndvi = 51
height.ndvi = 51
totalframes = 4464

i=0
#salspring
sspr.ndvi<-as.matrix(sspr.crop[[1]])
sspr.highdem<-as.matrix(sspr.crop[[2]])
sspr.lowdem<-as.matrix(sspr.lowrezdem)
ndvi.array<- array(0, dim=c(height.ndvi,width.ndvi,totalframes))
highres.array<- array(0, dim=c(height.dem,width.dem,totalframes))
highres.crop.array<- array(0, dim=c(height.ndvi,width.ndvi,totalframes))
lowres.array<- array(0, dim=c(height.dem,width.dem,totalframes))

i<-0
col=0
for(x in 1:totalcols){
  row=1
  col=col+1
  for(y in 1:totalrows){
    
    ndvi.rowmin<-ndvi.buffer + ((row-1)*high.step)+1
    ndvi.rowmax<-ndvi.rowmin+50
    ndvi.colmin<-ndvi.buffer + ((col-1)*high.step)+1
    ndvi.colmax<-ndvi.colmin+50
    NDVI<-sspr.ndvi[ndvi.rowmin:ndvi.rowmax,
                    ndvi.colmin:ndvi.colmax]
    highdem.rowmin<-dem.buffer + ((row-1)*high.step)+1 
    highdem.rowmax<-highdem.rowmin+152
    highdem.colmin<-dem.buffer + ((col-1)*high.step)+1
    highdem.colmax<-highdem.colmin+152
    highresDEM<-sspr.highdem[highdem.rowmin:highdem.rowmax,
                             highdem.colmin: highdem.colmax]
    highdem.crop.rowmin<-ndvi.buffer + ((row-1)*high.step)+1
    highdem.crop.rowmax<-highdem.crop.rowmin+50
    highdem.crop.colmin<-ndvi.buffer + ((col-1)*high.step)+1
    highdem.crop.colmax<-highdem.crop.colmin+50
    highdemcrop<-sspr.highdem[highdem.crop.rowmin:highdem.crop.rowmax,
                              highdem.crop.colmin:highdem.crop.colmax]
    lowdem.rowmin<-(row-1)*low.step+1
    lowdem.rowmax<-lowdem.rowmin+152
    lowdem.colmin<-(col-1)*low.step+1
    lowdem.colmax<-lowdem.colmin+152
    lowresDEM<-sspr.lowdem[lowdem.rowmin:lowdem.rowmax,
                           lowdem.colmin:lowdem.colmax]
    
    row=row+1
    i=i+1
    
    ndvi.array[,,i]<-NDVI
    highres.array[,,i]<-highresDEM
    highres.crop.array[,,i]<-highdemcrop
    lowres.array[,,i]<-lowresDEM
  }
}

#yelspring
yspr.ndvi<-as.matrix(yspr.crop[[1]])
yspr.highdem<-as.matrix(yspr.crop[[2]])
yspr.lowdem<-as.matrix(yspr.lowrezdem)
ndvi.array<- array(0, dim=c(height.ndvi,width.ndvi,totalframes))
highres.array<- array(0, dim=c(height.dem,width.dem,totalframes))
highres.crop.array<- array(0, dim=c(height.ndvi,width.ndvi,totalframes))
lowres.array<- array(0, dim=c(height.dem,width.dem,totalframes))

i<-0
col=0
for(x in 1:totalcols){
  row=1
  col=col+1
  for(y in 1:totalrows){
    
    ndvi.rowmin<-ndvi.buffer + ((row-1)*high.step)+1
    ndvi.rowmax<-ndvi.rowmin+50
    ndvi.colmin<-ndvi.buffer + ((col-1)*high.step)+1
    ndvi.colmax<-ndvi.colmin+50
    NDVI<-yspr.ndvi[ndvi.rowmin:ndvi.rowmax,
                 ndvi.colmin:ndvi.colmax]
    highdem.rowmin<-dem.buffer + ((row-1)*high.step)+1 
    highdem.rowmax<-highdem.rowmin+152
    highdem.colmin<-dem.buffer + ((col-1)*high.step)+1
    highdem.colmax<-highdem.colmin+152
    highresDEM<-yspr.highdem[highdem.rowmin:highdem.rowmax,
                    highdem.colmin: highdem.colmax]
    highdem.crop.rowmin<-ndvi.buffer + ((row-1)*high.step)+1
    highdem.crop.rowmax<-highdem.crop.rowmin+50
    highdem.crop.colmin<-ndvi.buffer + ((col-1)*high.step)+1
    highdem.crop.colmax<-highdem.crop.colmin+50
    highdemcrop<-yspr.highdem[highdem.crop.rowmin:highdem.crop.rowmax,
                    highdem.crop.colmin:highdem.crop.colmax]
    lowdem.rowmin<-(row-1)*low.step+1
    lowdem.rowmax<-lowdem.rowmin+152
    lowdem.colmin<-(col-1)*low.step+1
    lowdem.colmax<-lowdem.colmin+152
    lowresDEM<-yspr.lowdem[lowdem.rowmin:lowdem.rowmax,
                   lowdem.colmin:lowdem.colmax]
    
    row=row+1
    i=i+1
    
   ndvi.array[,,i]<-NDVI
   highres.array[,,i]<-highresDEM
   highres.crop.array[,,i]<-highdemcrop
   lowres.array[,,i]<-lowresDEM
  }
}

save(ndvi.array,file = "ndvi.RData")
save(highres.array,file = "highres.RData")
save(highres.crop.array,file = "highrescrop.RData")
save(lowres.array,file = "lowres.RData")

n=2000 #n=1056 is a good one for presentation
plot(raster(ndvi.array[,,n]))
plot(raster(highres.array[,,n]),ext=yel)
plot(raster(lowres.array[,,n]),ext=extent)
plot(raster(lowres.array[,,n]),ext=yel)
plot(raster(highres.array[,,n]))

#randomly sample
sample(x = 1:100,size = 1000,replace = TRUE)