#!/bin/bash

## Parameters ##
DAYSAGO=1047
RANGE=365 # the range of days to search for satellite imagery, $DAYSAGO - $RANGE = min_date
#FOLDERNAME=$(date -d "$DAYSAGO day ago" '+%Y-%m-%d') # THIS WONT WORK ON MAC OS, needs to be run visualization server, the date cmd takes diff inputs. Need date in "YYY-MM-DD" format (%Y-%m-%d)
FOLDERNAME=2016 # use to manually name the folder
LOCATION="Yellowstone"
OUTPUT="training"
CLOUD=20 #the acceptable % cloud cover 
LANDSAT_PATH=38 # Landsat 8 path
LANDSAT_ROW=29 # Landsat 8 row

#get data
kubectl delete pod getlandsat

read -r -d '' GET_LANDSAT << EOM
apiVersion: v1
kind: Pod
metadata:
  name: getlandsat
spec:
  containers:
  - name: getlandsat
    command: ["/bin/bash","-c"]
    args: [ "Rscript /mnt/nfs/script/rscripts/get_landsat_data.R DAYSAGO RANGE LOCATION LANDSAT_PATH LANDSAT_ROW CLOUD FOLDERNAME"]
    image: tristankcloud/rlandsat:latest
    resources:
      requests:
        ephemeral-storage: "64Mi"
      limits:
        cpu: "1000m"
        ephemeral-storage: "15Gi"
    stdinOnce: true
    volumeMounts:
      - mountPath: /mnt/nfs
        name: nfs
      - mountPath: /tmp
        name: tmp
      - mountPath: /cache
        name: cache-volume
  restartPolicy: Never
  volumes:
  - name: nfs
    nfs:
      path: /mnt/nfs
      server: 10.180.129.161
  - name: tmp
    nfs:
      path: /mnt/nfs/tmp
      server: 10.180.129.161
  - name: cache-volume
    nfs:
      path: /mnt/nfs/tmp
      server: 10.180.129.161
EOM

GET_LANDSAT=$(echo -e "$GET_LANDSAT" | sed 's/DAYSAGO/'"$DAYSAGO"'/')
GET_LANDSAT=$(echo -e "$GET_LANDSAT" | sed 's/RANGE/'"$RANGE"'/')
GET_LANDSAT=$(echo -e "$GET_LANDSAT" | sed 's/LOCATION/'"$LOCATION"'/')
GET_LANDSAT=$(echo -e "$GET_LANDSAT" | sed 's/LANDSAT_PATH/'"$LANDSAT_PATH"'/')
GET_LANDSAT=$(echo -e "$GET_LANDSAT" | sed 's/LANDSAT_ROW/'"$LANDSAT_ROW"'/')
GET_LANDSAT=$(echo -e "$GET_LANDSAT" | sed 's/CLOUD/'"$CLOUD"'/')
GET_LANDSAT=$(echo -e "$GET_LANDSAT" | sed 's/FOLDERNAME/'"$FOLDERNAME"'/')

echo -e "$GET_LANDSAT" | kubectl apply -f -

status=`kubectl get pods getlandsat -o jsonpath='{.status..phase}'`
while [ "$status" != "Succeeded" ]; do
    if [ "$status" ==  "Failed" ]; then
        echo "Failed"
        exit
    else
    sleep 1000
    fi 
  status=`kubectl get pods getlandsat -o jsonpath='{.status..phase}'`
done

#delete old pod
kubectl delete pod getlandsat

#clear unzipped folder
kubectl delete pod deletefiles

read -r -d '' DELETE_UNZIP << EOM
apiVersion: v1
kind: Pod
metadata:
  name: deletefiles
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 1000
  containers:
  - name: deletefiles
    command: ["/bin/bash","-c"]
    args: [ "/mnt/nfs/script/delete_old_files.sh LOCATION"]
    image: ubuntu:latest
    resources:
      limits:
        cpu: "500m"
    stdinOnce: true
    volumeMounts:
      - mountPath: /mnt/nfs
        name: nfs
      - mountPath: /tmp
        name: tmp
      - mountPath: /cache
        name: cache-volume
  restartPolicy: Never
  volumes:
  - name: nfs
    nfs:
      path: /mnt/nfs
      server: 10.180.129.161
  - name: tmp
    nfs:
      path: /mnt/nfs/tmp
      server: 10.180.129.161
  - name: cache-volume
    nfs:
      path: /mnt/nfs/tmp
      server: 10.180.129.161
EOM

DELETE_UNZIP=$(echo -e "$DELETE_UNZIP" | sed 's/LOCATION/'"$LOCATION"'/')

echo -e "$DELETE_UNZIP" | kubectl apply -f -

status=`kubectl get pods deletefiles -o jsonpath='{.status..phase}'`
while [ "$status" != "Succeeded" ]; do
    if [ "$status" ==  "Failed" ]; then
        echo "Failed"
        exit
    else
    sleep 5
    fi 
  status=`kubectl get pods deletefiles -o jsonpath='{.status..phase}'`
done
kubectl delete pod deletefiles

#unzip downloaded data
kubectl delete pod unziplandsat

read -r -d '' UNZIP << EOM
apiVersion: v1
kind: Pod
metadata:
  name: unziplandsat
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 1000
  containers:
  - name: unziplandsat
    command: ["/bin/bash","-c"]
    args: 
    - /mnt/nfs/script/unzip_landsat.sh FOLDERNAME LOCATION
    image: ubuntu:latest
    resources:
      limits:
        cpu: "500m"
    stdinOnce: true
    volumeMounts:
      - mountPath: /mnt/nfs
        name: nfs
      - mountPath: /tmp
        name: tmp     
      - mountPath: /cache
        name: cache-volume
  restartPolicy: Never
  volumes:
  - name: nfs
    nfs:
      path: /mnt/nfs
      server: 10.180.129.161
  - name: tmp
    nfs:
      path: /mnt/nfs/tmp
      server: 10.180.129.161
  - name: cache-volume
    nfs:
      path: /mnt/nfs/tmp
      server: 10.180.129.161

EOM

UNZIP=$(echo -e "$UNZIP" | sed 's/FOLDERNAME/'"$FOLDERNAME"'/')
UNZIP=$(echo -e "$UNZIP" | sed 's/LOCATION/'"$LOCATION"'/')

echo -e "$UNZIP" | kubectl apply -f -

status=`kubectl get pods unziplandsat -o jsonpath='{.status..phase}'`
while [ "$status" != "Succeeded" ]; do
    if [ "$status" ==  "Failed" ]; then
        echo "Failed"
        exit
    else
    sleep 5
    fi 
  status=`kubectl get pods unziplandsat -o jsonpath='{.status..phase}'`
done

echo "unzipping done"
kubectl delete pod unziplandsat

#process data
kubectl delete pod processlandsat

read -r -d '' PROCESS << EOM
apiVersion: v1
kind: Pod
metadata:
  name: processlandsat
spec:
  containers:
  - name: processlandsat
    command: ["/bin/bash","-c"]
    args: [ "Rscript /mnt/nfs/script/rscripts/process_raster.R LOCATION OUTPUT"]
    image: tristankcloud/rlandsat:latest
    resources:
      requests:
        ephemeral-storage: "64Mi"
      limits:
        cpu: "2000m"
        ephemeral-storage: "15Gi"
    stdinOnce: true
    volumeMounts:
      - mountPath: /mnt/nfs
        name: nfs
      - mountPath: /tmp
        name: tmp
      - mountPath: /cache
        name: cache-volume
  restartPolicy: Never
  volumes:
  - name: nfs
    nfs:
      path: /mnt/nfs
      server: 10.180.129.161
  - name: tmp
    nfs:
      path: /mnt/nfs/tmp
      server: 10.180.129.161
  - name: cache-volume
    nfs:
      path: /mnt/nfs/tmp
      server: 10.180.129.161
EOM
PROCESS=$(echo -e "$PROCESS" | sed 's/LOCATION/'"$LOCATION"'/')
PROCESS=$(echo -e "$PROCESS" | sed 's/OUTPUT/'"$OUTPUT"'/')

echo -e "$PROCESS" | kubectl apply -f -

status=`kubectl get pods processlandsat -o jsonpath='{.status..phase}'`
while [ "$status" != "Succeeded" ]; do
    if [ "$status" ==  "Failed" ]; then
        echo "Failed"
        exit
    else
    sleep 60
    fi 
  status=`kubectl get pods processlandsat -o jsonpath='{.status..phase}'`
done
echo "processing done"
kubectl delete pod processlandsat

#clear /tmp 
sudo rm -r /tmp/Rtmp*

#pass metadata
kubectl delete pod passmetadata

 read -r -d '' METADATA << EOM
apiVersion: v1
kind: Pod
metadata:
  name: passmetadata
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 1000
  containers:
  - name: passmetadata
    command: ["/bin/bash","-c"]
    args: 
    - /mnt/nfs/script/pass_extra_variables.sh LOCATION OUTPUT FOLDERNAME
    image: ubuntu:latest
    resources:
      limits:
        cpu: "500m"
    stdinOnce: true
    volumeMounts:
      - mountPath: /mnt/nfs
        name: nfs
      - mountPath: /tmp
        name: tmp     
      - mountPath: /cache
        name: cache-volume
  restartPolicy: Never
  volumes:
  - name: nfs
    nfs:
      path: /mnt/nfs
      server: 10.180.129.161
  - name: tmp
    nfs:
      path: /mnt/nfs/tmp
      server: 10.180.129.161
  - name: cache-volume
    nfs:
      path: /mnt/nfs/tmp
      server: 10.180.129.161

EOM
METADATA=$(echo -e "$METADATA" | sed 's/LOCATION/'"$LOCATION"'/')
METADATA=$(echo -e "$METADATA" | sed 's/OUTPUT/'"$OUTPUT"'/')
METADATA=$(echo -e "$METADATA" | sed 's/FOLDERNAME/'"$FOLDERNAME"'/')

echo -e "$METADATA" | kubectl apply -f -

status=`kubectl get pods passmetadata -o jsonpath='{.status..phase}'`
while [ "$status" != "Succeeded" ]; do
    if [ "$status" ==  "Failed" ]; then
        echo "Failed"
        exit
    else
    sleep 5
    fi 
  status=`kubectl get pods passmetadata -o jsonpath='{.status..phase}'`
done
echo "metadata done"

kubectl delete pod passmetadata

# clear unzipped folder
echo -e "$DELETE_UNZIP" | kubectl apply -f -

status=`kubectl get pods deletefiles -o jsonpath='{.status..phase}'`
while [ "$status" != "Succeeded" ]; do
    if [ "$status" ==  "Failed" ]; then
        echo "Failed"
        exit
    else
    sleep 5
    fi 
  status=`kubectl get pods deletefiles -o jsonpath='{.status..phase}'`
done
kubectl delete pod deletefiles

echo "done"
exit