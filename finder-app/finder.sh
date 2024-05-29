#!/bin/sh
#	Assignment1 finder app script
#	Author: Mohamed Abdelsamie

#	CHECK SCRIPT INPUTS FIRST
if [ $# -ne 2 ]
then
    echo "Error: Please provide both path and search string"
    exit 1
fi

#	variable 1 --> directory to search in
filesdir=$1
#	variable 2 --> string to look for
searchstr=$2

if [ ! -d $filesdir ]
then
    echo "Error: ${filesdir} no such directory name exists"
    exit 1
elif [ ! -r $filesdir ]
then
	echo "Error: ${filesdir} doesn\'t have read persmission"
    exit 1
fi

#   find command to search for files and pipe output to next to command to count'em
file_count=$(find "$filesdir" -type f | wc -l)

#   look for string in those files and print number of hits
match_count=$(grep -r "$searchstr" "$filesdir" | wc -l)

#   print out results
echo "The number of files are ${file_count} and the number of matching lines are ${match_count}"
