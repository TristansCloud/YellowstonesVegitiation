#!/bin/bash
# example: ./unzip.sh "2019-04-12" "Yellowstone"

mkdir -p /mnt/nfs/data/$2/unzipped/$1 && chmod 777 /mnt/nfs/data/$2/unzipped/$1

for a in /mnt/nfs/data/$2/original_data/$1/*.tar.gz
do
    name=`expr $a : '\(.*\).tar.gz'`
    mkdir -p /mnt/nfs/data/$2/unzipped/$1/${name##*/} && chmod 777 /mnt/nfs/data/$2/unzipped/$1/${name##*/}
    tar -oxvzf $a -C /mnt/nfs/data/$2/unzipped/$1/${name##*/}
done