#!/bin/sh

dir=$1
str=$2

if [[ -z "$str" ]] || [[ -z "$dir" ]]
then
	echo "Missing parameter"
	exit 1
fi

if [[ ! -d "$dir" ]]
then
	echo "Directory does not exist"
	exit 1
fi

var1=$(grep -r -o "$str*" "$dir" | wc -l)
var2=$(grep -r -l "$str*" "$dir" | wc -l)


echo "The number of files are ${var2} and the number of matching lines are ${var1}"
