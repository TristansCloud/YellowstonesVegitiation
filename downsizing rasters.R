library(raster)
library(mgcv)
salsummer<-stack("/mnt/nfs/data/SalmonChallis/training/2016/LC080410292016072401T1-SC20191028014713/LC080410292016072401T1-SC20191028014713.tif")
salspring<-stack("/mnt/nfs/data/SalmonChallis/training/2016/LC080410292016062201T1-SC20191028014713/LC080410292016062201T1-SC20191028014713.tif")
2.774, middle = 115.018, range = 0.7 xmin = -114.3245, xmax = -115.718
2.153, middle = 44.59383,range = .53825, ymin = 44.05558, ymax = 45.13208

cropto<-matrix(c(-114.3245, 44.55558,
                 -114.3245, 45.13208,
                 -115.718, 45.13208,
                 -115.718, 44.55558,
                 -114.3245, 44.55558),
               ncol = 2, byrow = TRUE)
plot(sal.image,ext = cropto)
summer<-crop(salsummer,cropto)
spring<-crop(salspring,cropto)
rm(sal.image)



ndvi.spring<-as.integer(as.vector(spring[[2]]))
aspect.spring<-as.integer(as.vector(spring[[6]]))
dem.spring<-as.integer(as.vector(spring[[3]]))
tri.spring<-as.integer(as.vector(spring[[7]]))
slope.spring<-as.integer(as.vector(spring[[5]]))
neighborflow.spring<-as.integer(log2(as.vector(spring[[8]])))

ndvi.summer<-as.integer(as.vector(summer[[2]]))
aspect.summer<-as.integer(as.vector(summer[[6]]))
dem.summer<-as.integer(as.vector(summer[[3]]))
tri.summer<-as.integer(as.vector(summer[[7]]))
slope.summer<-as.integer(as.vector(summer[[5]]))
neighborflow.summer<-as.integer(log2(as.vector(summer[[8]])))


spring.matrix<-matrix(c(ndvi.spring,aspect.spring,dem.spring,tri.spring,slope.spring,neighborflow.spring),ncol = 6)
colnames(spring.matrix)<-c("ndvi","aspect","dem","tri","slope","neighborflow")
spring.matrix <- spring.matrix[spring.matrix[,1] >= 0,]
spring.matrix <- spring.matrix[spring.matrix[,1] <= 8000,]
spring.test<-spring.matrix[seq(1, nrow(spring.matrix), 2), ]
spring.val<-spring.matrix[seq(2, nrow(spring.matrix), 2), ]

summer.matrix<-matrix(c(ndvi.summer,aspect.summer,dem.summer,tri.summer,slope.summer,neighborflow.summer),ncol = 6)
colnames(summer.matrix)<-c("ndvi","aspect","dem","tri","slope","neighborflow")


summary(gam(spring.test[,1]~s(spring.test[,2],bs="cr")+s(spring.test[,3],bs="cr")+s(spring.test[,6],bs="cr")))


# summer

summer.matrix<-matrix(c(ndvi.summer,aspect.summer,dem.summer,tri.summer,slope.summer,neighborflow.summer),ncol = 6)
colnames(summer.matrix)<-c("ndvi","aspect","dem","tri","slope","neighborflow")
summer.matrix <- summer.matrix[summer.matrix[,1] >= 0,]
summer.matrix <- summer.matrix[summer.matrix[,1] <= 8000,]
summer.test<-summer.matrix[seq(1, nrow(summer.matrix), 2), ]
summer.val<-summer.matrix[seq(2, nrow(summer.matrix), 2), ]

summary(gam(summer.test[,1]~s(summer.test[,2],bs="cr")+s(summer.test[,3],bs="cr")+s(summer.test[,4],bs="cr")+s(summer.test[,5],bs="cr")+s(summer.test[,6],bs="cr")))


