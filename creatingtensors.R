library(raster)


salspring<-stack("/mnt/nfs/Rstudio/data/salchallisspring.tif",bands=c(2,3))
salsummer<-stack("/mnt/nfs/Rstudio/data/salchallissummer.tif",bands=c(2,3))
yelspring<-stack("/mnt/nfs/Rstudio/data/yellowstonespring.tif",bands=c(2,3))
yelsummer<-stack("/mnt/nfs/Rstudio/data/yellowstonesummer.tif",bands=c(2,3))

rasters<-list(salspring,salsummer,yelspring,yelsummer)

for(i in rasters){
  i[[1]]<-i[[1]]/10000
  i[[2]]<-(i[[2]]+100)/9000
}

rast1<-stack(raster(matrix(runif(100),
                   ncol = 10, byrow = TRUE)),
             raster(matrix(runif(100),
                           ncol = 10, byrow = TRUE)))
rasters<-list(rast1,rast1)
for(i in seq_along(rasters) ) {
  #rasters[[i]][1]<-rasters[[i]][1]/10000
  #rasters[[i]][2]<-(rasters[[i]][2]+100)/9000
  plot(raster[i][[1]])
  plot(raster[i][[2]])
  
}
