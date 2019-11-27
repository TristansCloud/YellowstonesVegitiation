# DAYS_AGO  RANGE CLOUD
args<-commandArgs(trailingOnly=TRUE)

max_date = as.character(Sys.Date()-as.numeric(args[1]))
min_date = as.character(Sys.Date()-(as.numeric(args[1])+as.numeric(args[2])))
path<-as.numeric(args[4])
row<-as.numeric(args[5])
cloud<-as.numeric(args[6])
foldername<-args[7]
for(i in args){
    print(typeof(i))
}
print(args)
print(list(max_date,min_date,path,row,cloud,foldername))
for(i in list(max_date,min_date,path,row,cloud,foldername)){
    print(typeof(i))
}

#landsat package and creds
library(rLandsat)
espa_creds("triskos", "DxzWRXMBF843")

# get all the products, define path and row
result = landsat_search(min_date = min_date, max_date = max_date, path_master = path, row_master = row,source="usgs")
print("got results")
print(result$cloud_cover_land)
result = base::subset(result, result$cloud_cover_land<=cloud)
print("subset")
print(result$cloud_cover_land)
# placing an espa order
result_order = espa_order(result$landsat_product_id, product = c("sr_ndvi"),
                          projection = "lonlat",
                          order_note = "National forest")

if (is.null(result_order[["order_details"]][["status"]])) {
  available = data.frame(result_order["product_available"])
  available = base::subset(available, product_available.sr_ndvi == 1)
  available = base::subset(available, product_available.pixel_qa == 1)
}
result_order = espa_order(available$product_available.product_id, product = c("sr_ndvi"),
                          projection = "lonlat",
                          order_note = "National forest")

order_id = result_order$order_details$orderid
print(order_id)
Sys.sleep(100)
# quit if order fails, should add other statements to help debug order failure (no data available, could not reach server)
if(result_order[["order_details"]][["status"]]!="ordered"){
    print("order failed")
    q(save = "no")
}

# getting order status
durl = espa_status(order_id = order_id, getSize = TRUE)

# loop to wait for order to be ready
print("waiting for order")
print(durl[["order_details"]][["status"]])

while(durl[["order_details"]][["status"]][1]!="complete"){
    Sys.sleep(1000)
    durl = espa_status(order_id = order_id, getSize = TRUE)
}

Sys.sleep(100)

print(durl[["order_details"]][["status"]])

# create directories and set permissions
dir.create(file.path("/mnt/nfs/data",as.character(args[3]),"original_data",foldername))
Sys.chmod(file.path("/mnt/nfs/data",as.character(args[3]),"original_data",foldername), mode = "777", use_umask = FALSE)
setwd(file.path("/mnt/nfs/data",as.character(args[3]),"original_data",foldername))

# download landsat data
downurl = durl$order_details
landsat_download(download_url = downurl$product_dload_url, dest_file = getwd())