#!/bin/bash
QADIR="$HOME/.ReportQA"
cd $QADIR

FN="$1"
SN="$2"
INC="$3"

cat junk/SubV.txt | sort|uniq > junk/SubV.tmp
F1="$(
cat junk/SubV.tmp|awk  -F'#' '$1=/KEY/{print $2}' |
awk -F'=' -v OFS='=' -v AF="$FN" '{
for(n=1;n<=NF;n++)
    {
        if(index($n, AF))
            {
                print $n;
            }
        }
    }'
)"
[ "$F1" == "" ] && exit

for V in $(cat junk/SubV.tmp |awk -F'#' '{if($1 == "1"){print $2}}')
do
        NN=@$(($(echo "$V"|tr -d '$')+1))
        F1=$(echo ${F1//$V/$NN})
done


F2="$(
cat junk/SubV.tmp|awk  -F'#' '$1=/KEY/{print $2}' |
awk -F'=' -v OFS='=' -v AF="$SN" '{
for(n=1;n<=NF;n++)
    {
        if(index($n, AF))
            {
                print $n;
            }
        }
    }'
)"

for V in $(cat junk/SubV.tmp |awk -F'#' '{if($1 == "2"){print $2}}')
do
        NN=@$(($(echo "$V"|tr -d '$')+1+INC))
        F2=$(echo ${F2//$V/$NN})
done

cat junk/SubV.tmp|awk  -F'#' '$1=/KEY/{print $2}' |
J=$(
awk -v W1="$FN" -v W2="$SN" '
{
    if (index($0, W1) > index($0, W2))
        {
            print "1";
        }
    else
        {
            print "0";
        }
}
'
)

if [ "$J" == "1" ];then
    str="$F1==$F2"
else
    str="$F2==$F1"
fi
echo ${str//@/\$} >> junk/CompareSelf.grules
