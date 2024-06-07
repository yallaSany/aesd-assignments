#!/bin/bash

file="$1"
str="$2"
dir=$PWD

if [[ -z "$str" ]] || [[ -z "$file" ]]
then
        echo "Missing parameter"
        exit 1
fi

cd /

dirname $1 | xargs  mkdir -p

echo $str>$file

cd $dir
