#!/bin/bash

#./RulesMake.sh WFPrepaymentArm/gnarm.txt SelfRules
#./RulesMake.sh WFServicerArm/fh.txt WFPrepaymentArm/g2arm.txt CT $1=$1%$2=$2%$3=$4

QADIR="$HOME/.ReportQA"

ProgName=$(basename $0)
FNAME="$1"
SNAME="$2"
TNAME="$3"


function Self()
{
    local FNAME="$1"
    local SNAME="$2"

    sed -n "/<_dir_-_file_>/p" $QADIR/Rules/SelfRules.temp| sed -n "s/_dir_/$(dirname $FNAME)/; s/_file_/$(basename $FNAME)/; p" > /tmp/$ProgName.$$
    cat $SNAME >> /tmp/$ProgName.$$
    sed -n "/<\/_dir_-_file_>/p" $QADIR/Rules/SelfRules.temp| sed -n "s/_dir_/$(dirname $FNAME)/; s/_file_/$(basename $FNAME)/; p" >> /tmp/$ProgName.$$
   cat /tmp/$ProgName.$$ 
   echo
}

function Compare()
{
   local FNAME="$1"
   local SNAME="$2"
   local TNAME="$3"

   sed -n "/<_dir1_-_file1_-V-_dir2_-_file2_>/p" $QADIR/Rules/CompareRules.temp| sed -n "s/_dir1_/$(dirname $FNAME)/; s/_file1_/$(basename $FNAME)/; s/_dir2_/$(dirname $SNAME)/; s/_file2_/$(basename $SNAME)/; p" > junk/$ProgName.$$

    #}cat $TNAME >> /tmp/$ProgName.$$
    cat $TNAME |sed -n "s/f/$(echo $FNAME|awk -F'/' '{print $1"-"$2"|"}')/g; s/s/$(echo $SNAME|awk -F'/' '{print $1"-"$2"|"}')/g; p" >> junk/$ProgName.$$
    sed -n "/<\/_dir1_-_file1_-V-_dir2_-_file2_>/p" $QADIR/Rules/CompareRules.temp| sed -n "s/_dir1_/$(dirname $FNAME)/; s/_file1_/$(basename $FNAME)/; s/_dir2_/$(dirname $SNAME)/; s/_file2_/$(basename $SNAME)/; p" >> junk/$ProgName.$$
   cat junk/$ProgName.$$ 
   echo

}

[ -f "$FNAME" -a -f "$SNAME" -a $# -eq 2 ] && Self "$FNAME" "$SNAME"

[ -f "$FNAME" -a -f "$SNAME" -a  -f "$TNAME" -a $# -eq 3 ] && Compare "$FNAME" "$SNAME" "$TNAME"
