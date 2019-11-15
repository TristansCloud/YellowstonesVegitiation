library(raster)
library(rgdal)
options(rasterMaxMemory = 1e10) #10Gb of ram max

args<-commandArgs(trailingOnly=TRUE)
input = file.path("/mnt/nfs/data/SalmonChallis",as.character(args[1]),fsep="/")
output = file.path("/mnt/nfs/data",as.character(args[1]),as.character(args[2]),fsep="/") #path to where the data should go
name = "hello" # intitialize object so delete old /tmp works on first iteration of loop
print(args)
print(as.character(args))
#get directories that have data that needs to be processed
directory = list.dirs(path = input, recursive = FALSE)
for(direct in directory) {
    subdirect = list.dirs(path = direct,recursive = FALSE)
    for(sub in subdirect){

        # name of datapull
        name_old = name
        name = gsub(paste(direct,"/",sep=""),"",sub)
        print(c("working in",name))

        # set new /tmp directory
        dir.create(file.path("/tmp",name, fsep="/"), recursive = TRUE)
        rasterOptions(tmpdir=file.path("/tmp",name, fsep="/"))

        # delete old /tmp directorh\y
        unlink(file.path("/tmp",name_old,fsep="/"), recursive = TRUE)

        # get paths to basemaps
        DEM = raster(file.path("/mnt/nfs/data",as.character(args[1]),"base_layers/dem.tif",fsep="/"))
        flow_accum = raster(file.path("/mnt/nfs/data",as.character(args[1]),"base_layers/accumulation.tif",fsep="/"))
        slope = raster(file.path("/mnt/nfs/data",as.character(args[1]),"base_layers/slope.tif",fsep="/"))
        aspect = raster(file.path("/mnt/nfs/data",as.character(args[1]),"base_layers/aspect.tif",fsep="/"))
        ruggedness = raster(file.path("/mnt/nfs/data",as.character(args[1]),"base_layers/tri.tif",fsep="/"))
        neighbor_flow = raster(file.path("/mnt/nfs/data",as.character(args[1]),"base_layers/neighbor_flow.tif",fsep="/"))

        files_for_raster <- list.files(path = sub, pattern = "*.tif$", full.names = TRUE)
        rasterstack = stack(files_for_raster)

        # crop DEM to the extent of the satellite image
        DEMcrop = crop(DEM,rasterstack) #extent can be a raster
        flow_accumcrop = crop(flow_accum,rasterstack)
        slopecrop = crop(slope,rasterstack)
        aspectcrop = crop(aspect,rasterstack)
        ruggednesscrop = crop(ruggedness,rasterstack)
        neighbor_crop = crop(neighbor_flow,rasterstack)

        print(c("cropped"))
        print(object.size(DEMcrop))
        print(object.size(rasterstack))

        # resample rasters, this will take a bit
        DEMcrop = resample(DEMcrop,rasterstack) 
        flow_accumcrop = resample(flow_accumcrop,rasterstack)
        slopecrop = resample(slopecrop,rasterstack)
        aspectcrop = resample(aspectcrop,rasterstack)
        ruggednesscrop = resample(ruggednesscrop,rasterstack)
        neighbor_crop = resample(neighbor_crop,rasterstack)
        print(c("resampled"))
        print(object.size(DEMcrop))
        print(object.size(rasterstack))

        # mask layers 
        DEMcrop = mask(DEMcrop,raster::subset(rasterstack,1)) 
        flow_accumcrop = mask(flow_accumcrop,raster::subset(rasterstack,1))
        slopecrop = mask(slopecrop,raster::subset(rasterstack,1))
        aspectcrop = mask(aspectcrop,raster::subset(rasterstack,1))
        ruggednesscrop = mask(ruggednesscrop,raster::subset(rasterstack,1))
        neighbor_crop = mask(neighbor_crop,raster::subset(rasterstack,1))
        print(c("masked"))
        print(object.size(DEMcrop))
        print(object.size(rasterstack))

        # add baselayers to the raster stack
        finalstack = addLayer(rasterstack,DEMcrop,flow_accumcrop,slopecrop,aspectcrop,ruggednesscrop,neighbor_crop)
        print(names(finalstack))
        print(nlayers(finalstack))
        bands<-c("band1","band2","band3","band4","band5","band6","band7","band8")
        type<-c("quality","sr_ndvi","DEM","flow_accum","slope","aspect","TRI","neighbor_accum")
        band_info<-data.frame(bands,type)
        
        print("finalstack")
        print(object.size(finalstack))

        # create new output directory and save raster there
        output_subdirect = gsub(paste(input,"/",sep=""),"",sub)
        dir.create(file.path(output,output_subdirect), recursive = TRUE)
        Sys.chmod(file.path(output,output_subdirect), mode = "777", use_umask = FALSE)
        print("created directory")
        write = file.path(output,output_subdirect)
        writeRaster(finalstack, format="GTiff", filename=file.path(write,name,fsep="/"), options=c("INTERLEAVE=BAND","COMPRESS=NONE"), overwrite=TRUE)
        write.csv(band_info, file = paste(file.path(write,name,fsep="/"),".csv",sep=""))
        print("done processing")
        rm(rasterstack,DEMcrop,flow_accumcrop,slopecrop,aspectcrop,ruggednesscrop,neighbor_crop)
        gc()
        print(gc())
        system("sysctl -w vm.drop_caches=3")
    }
}
unlink(file.path("/tmp",name,fsep="/"), recursive = TRUE)

# useful functions
#mystack = stack("path/to/multilayer.tif") # multilayer.tif is an existing raster stack
#band1 = subset(mystack,subset=1) # subsets bands from raster stack
#removeTmpFiles(h=0) # removes temp files, can be used after writing raster stackes to delete all temp raster files
#rasterbrick<-brick(rasterstack) #can make a raster brick from a raster stack
