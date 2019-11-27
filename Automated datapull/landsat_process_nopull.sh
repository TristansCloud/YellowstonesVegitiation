#!/bin/bash

## Parameters ## Example: ./landsat_process_nopull.sh 2016 Yellowstone training
FOLDERNAME=$1 #2016 or 2019-10-11 etc.
LOCATION=$2 #Yellowstone or SalmonChallis
OUTPUT=$3 #training or validation

#clear unzipped folder
kubectl delete pod deletefiles1

read -r -d '' DELETE_UNZIP << EOM
apiVersion: v1
kind: Pod
metadata:
  name: deletefiles1
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 1000
  containers:
  - name: deletefiles1
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

status=`kubectl get pods deletefiles1 -o jsonpath='{.status..phase}'`
while [ "$status" != "Succeeded" ]; do
    if [ "$status" ==  "Failed" ]; then
        echo "Failed"
        exit
    else
    sleep 5
    fi 
  status=`kubectl get pods deletefiles1 -o jsonpath='{.status..phase}'`
done
kubectl delete pod deletefiles1

#unzip downloaded data
kubectl delete pod unziplandsat1

read -r -d '' UNZIP << EOM
apiVersion: v1
kind: Pod
metadata:
  name: unziplandsat1
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 1000
  containers:
  - name: unziplandsat1
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

status=`kubectl get pods unziplandsat1 -o jsonpath='{.status..phase}'`
while [ "$status" != "Succeeded" ]; do
    if [ "$status" ==  "Failed" ]; then
        echo "Failed"
        exit
    else
    sleep 5
    fi 
  status=`kubectl get pods unziplandsat1 -o jsonpath='{.status..phase}'`
done

echo "unzipping done"
kubectl delete pod unziplandsat1

#process data
kubectl delete pod processlandsat1

read -r -d '' PROCESS << EOM
apiVersion: v1
kind: Pod
metadata:
  name: processlandsat1
spec:
  containers:
  - name: processlandsat1
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

status=`kubectl get pods processlandsat1 -o jsonpath='{.status..phase}'`
while [ "$status" != "Succeeded" ]; do
    if [ "$status" ==  "Failed" ]; then
        echo "Failed"
        exit
    else
    sleep 60
    fi 
  status=`kubectl get pods processlandsat1 -o jsonpath='{.status..phase}'`
done
echo "processing done"
kubectl delete pod processlandsat1

#clear /tmp 
sudo rm -r /tmp/Rtmp*

#pass metadata
kubectl delete pod passmetadata1

 read -r -d '' METADATA << EOM
apiVersion: v1
kind: Pod
metadata:
  name: passmetadata1
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 1000
  containers:
  - name: passmetadata1
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

status=`kubectl get pods passmetadata1 -o jsonpath='{.status..phase}'`
while [ "$status" != "Succeeded" ]; do
    if [ "$status" ==  "Failed" ]; then
        echo "Failed"
        exit
    else
    sleep 5
    fi 
  status=`kubectl get pods passmetadata1 -o jsonpath='{.status..phase}'`
done
echo "metadata done"

kubectl delete pod passmetadata1

# clear unzipped folder
echo -e "$DELETE_UNZIP" | kubectl apply -f -

status=`kubectl get pods deletefiles1 -o jsonpath='{.status..phase}'`
while [ "$status" != "Succeeded" ]; do
    if [ "$status" ==  "Failed" ]; then
        echo "Failed"
        exit
    else
    sleep 5
    fi 
  status=`kubectl get pods deletefiles1 -o jsonpath='{.status..phase}'`
done
kubectl delete pod deletefiles1

echo "done"
exit