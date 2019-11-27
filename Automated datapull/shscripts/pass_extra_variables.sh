#!/bin/bash

for a in /mnt/nfs/data/$1/unzipped/$3/*/*.txt
do
    folder="$(cut -d'/' -f8 <<< "$a")"
    name=`expr $a : '\(.*\).txt'`
    name=${name##*/}
    name+=".txt"
    cp -f $a /mnt/nfs/data/$1/$2/$3/$folder/${name##*/}
done

for b in /mnt/nfs/data/$1/unzipped/$3/*/*.xml
do
    folder="$(cut -d'/' -f8 <<< "$b")"
    name=`expr $b : '\(.*\).xml'`
    name=${name##*/}
    name+=".xml"
    cp -f $b /mnt/nfs/data/$1/$2/$3/$folder/${name##*/}
done