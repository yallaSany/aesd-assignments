#!/bin/sh
#	Assignment1 writer app script
#	Author: Mohamed Abdelsamie

#   check input arguments first
if [ $# -ne 2 ]
then
    echo "Error: missing or too few argument\s"
    exit 1
fi

#   first input argument is the file being written into
writefile=$1

#   second inpit argument is what's being written into the file
writestr=$2

#   no test needed i just need to create directory so lose parentheses here
if ! mkdir -p "$(dirname "$writefile")"
then
    echo "Error: Failed to create directory for file $writefile"
    exit 1
fi


if ! echo "$writestr" > "$writefile"
then
    echo "Error: Failed to write to file $writefile"
    exit 1
fi
