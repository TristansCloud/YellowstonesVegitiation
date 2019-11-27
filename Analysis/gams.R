library(raster)
library(tabplot)
library(mgcv)
library(data.table)

salspring<-stack("/mnt/nfs/Rstudio/data/salchallisspring.tif")
salsummer<-stack("/mnt/nfs/Rstudio/data/salchallissummer.tif")
yelspring<-stack("/mnt/nfs/Rstudio/data/yellowstonespring.tif")
yelsummer<-stack("/mnt/nfs/Rstudio/data/yellowstonesummer.tif")

# converting to vectors, ignore image[[4]], I'm using neighbor flow instead.

salspring.ndvi<-as.vector(salspring[[2]])
salspring.dem<-as.vector(salspring[[3]])
salspring.slope<-as.vector(salspring[[5]])
salspring.aspect<-as.vector(salspring[[6]])
salspring.tri<-as.vector(salspring[[7]])
salspring.flow<-as.vector(salspring[[8]])
salspring.tbl<-as.data.table(matrix(c(salspring.ndvi,salspring.dem,salspring.slope,salspring.aspect,salspring.tri,salspring.flow),ncol = 6))
colnames(salspring.tbl)<-c("ndvi","dem","slope","aspect","tri","flow")
rm(salspring.ndvi,salspring.dem,salspring.slope,salspring.aspect,salspring.tri,salspring.flow)

salsummer.ndvi<-as.vector(salsummer[[2]])
salsummer.dem<-as.vector(salsummer[[3]])
salsummer.slope<-as.vector(salsummer[[5]])
salsummer.aspect<-as.vector(salsummer[[6]])
salsummer.tri<-as.vector(salsummer[[7]])
salsummer.flow<-as.vector(salsummer[[8]])
salsummer.tbl<-as.data.table(matrix(c(salsummer.ndvi,salsummer.dem,salsummer.slope,salsummer.aspect,salsummer.tri,salsummer.flow),ncol = 6))
colnames(salsummer.tbl)<-c("ndvi","dem","slope","aspect","tri","flow")
rm(salsummer.ndvi,salsummer.dem,salsummer.slope,salsummer.aspect,salsummer.tri,salsummer.flow)


yelspring.ndvi<-as.vector(yelspring[[2]])
yelspring.dem<-as.vector(yelspring[[3]])
yelspring.slope<-as.vector(yelspring[[5]])
yelspring.aspect<-as.vector(yelspring[[6]])
yelspring.tri<-as.vector(yelspring[[7]])
yelspring.flow<-as.vector(yelspring[[8]])
yelspring.tbl<-as.data.table(matrix(c(yelspring.ndvi,yelspring.dem,yelspring.slope,yelspring.aspect,yelspring.tri,yelspring.flow),ncol = 6))
colnames(yelspring.tbl)<-c("ndvi","dem","slope","aspect","tri","flow")
rm(yelspring.ndvi,yelspring.dem,yelspring.slope,yelspring.aspect,yelspring.tri,yelspring.flow)

yelsummer.ndvi<-as.vector(yelsummer[[2]])
yelsummer.dem<-as.vector(yelsummer[[3]])
yelsummer.slope<-as.vector(yelsummer[[5]])
yelsummer.aspect<-as.vector(yelsummer[[6]])
yelsummer.tri<-as.vector(yelsummer[[7]])
yelsummer.flow<-as.vector(yelsummer[[8]])
yelsummer.tbl<-as.data.table(matrix(c(yelsummer.ndvi,yelsummer.dem,yelsummer.slope,yelsummer.aspect,yelsummer.tri,yelsummer.flow),ncol = 6))
colnames(yelsummer.tbl)<-c("ndvi","dem","slope","aspect","tri","flow")
rm(yelsummer.ndvi,yelsummer.dem,yelsummer.slope,yelsummer.aspect,yelsummer.tri,yelsummer.flow)

# splitting yellowstone into flatland and mountains
#110.4032 = split
yelspring.mnt<-




## GAMs ##

# spring
bam.fullmodel.spring<-bam(ndvi~s(dem,bs="cr")+s(slope,bs="cr")+s(aspect,bs="cr")+s(tri,bs="cr")+s(flow,bs="cr"),data = salspring.tbl)
bam.red.spring<-bam(ndvi~s(dem,bs="cr"),data = salspring.tbl)
bam.dropaspect.spring<-bam(ndvi~s(aspect,bs="cr"),data = salspring.tbl)


bam.pred.yelspring<-predict(bam.red.spring,salspring.tbl)
cor(bam.pred.yelspring,salspring.tbl$ndvi)

a<-predict(bam.red.spring,yelsummer.tbl)
cor(a,yelsummer.tbl$ndvi)

# summer
bam.fullmodel.summer<-bam(ndvi~s(dem,bs="cr")+s(slope,bs="cr")+s(aspect,bs="cr")+s(tri,bs="cr")+s(flow,bs="cr"),data = salsummer.tbl)
bam.red.summer<-bam(ndvi~s(dem,bs="cr")+s(aspect,bs="cr")+s(flow,bs="cr"),data = salsummer.tbl)
bam.dropaspect.summer<-bam(ndvi~s(dem,bs="cr"),data = salsummer.tbl)

bam.pred.yelsummer<-predict(bam.dropaspect.summer,yelsummer.tbl)
cor(bam.pred.yelsummer,yelsummer.tbl$ndvi)

a<-predict(bam.red.summer,yelspring.tbl)
cor(a,yelspring.tbl$ndvi)


# old

summer.bam<-bam(ndvi~s(aspect,bs="cr")+s(tri,bs="cr")+s(slope,bs="cr")+s(dem,bs="cr")+s(neighborflow,bs="cr"),data = summer.test)
summary(summer.bam)
plot.gam(summer.bam)

summer.predict<-data.table(predict.bam(summer.bam,newdata = summer.val,type = "response",se=FALSE))
s<-cbind(summer.predict,summer.val$ndvi)
cor(s$V1,s$V2)
# predicting

a<-data.table(predict.gam(gam_hap_np,newdata = cpue_val,type = "response",se=FALSE))
