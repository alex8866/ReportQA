#!/bin/bash
#check Self, 前提是文件名明明有规律
#FILES are all directory
#./CheckReport.sh WFPrepaymentArm SelfRulesAll
#./CheckReport.sh WFPrepaymentArm WFServicerArm CompareRulesAll

QADIR="$HOME/.ReportQA"
cd $QADIR

ProgName=$(basename $0)
FNAME="$1"
SNAME="$2"
TNAME="$3"


function FormatFile()
{
   local FileName=$(basename "$1")

   > junk/$FileName.remove
   #combine the key field and add to the first
   cat "$1" |awk -F'\t' -v OFS="\t" -v FNM="junk/$FileName.remove" '
   {
       for(n = 1; n <= NF; n++)
           {
               gsub(/^[[:blank:]]*/,"",$(n));
               gsub(/[[:blank:]]*$/,"",$(n));
               gsub(/\$/,"",$(n));
               gsub(/,/,"",$(n));
               $(n)=(match($(n),/[a-z,A-Z]/)?$(n):strtonum($(n)))
               #如果报告中所有大小写统一则, 该行可注释
               #$(n)=($(n)==""?$(n):toupper($(n)));
           }
        print $0
   }
   '
    
}

function GetSelfRule()
{
    local FNAME="$1"
    local SNAME="$2"
    fs=$(echo "$FNAME"|cut -d'/' -f1)-$(echo "$FNAME"|cut -d'/' -f2)
    cat "$SNAME" | 
    sed -n -e "/<$fs>/,/<\/$fs>/p" |
    grep -v "$(dirname "$FNAME")-$(basename "$FNAME")"
}


function GetCompareRule()
{
    local FNAME="$1"
    local SNAME="$2"
    local TNAME="$3"

    #get flag str
    var=$(cat "$TNAME" | egrep ".*-V-.*"|egrep -v "^</" |grep "$(dirname "$FNAME")-$(basename "$FNAME")" |
    grep "$(dirname "$SNAME")-$(basename "$SNAME")")

    [ "$var" == "" ] && exit
    fs=$(echo "$var" | tr -d '<>')

    cat "$TNAME"|sed -n -e "/<$fs>/,/<\/$fs>/p" |
    grep -v "$fs"
}


function GenSelfAwk()
{
    cp Rules/CheckSelf.awk.temp  junk/CheckSelf.awk.$$
    cat "$1" |sed '/^$/d' > $1.sed
    while read line
    do
        cat << EOF >> junk/CheckSelf.awk.$$
        if ($line)
            {
                ;
            }
        else
            {
                
                #condition="$line";
                condition="${line//\"/}"
                print \$0" ##### "condition;
            }

EOF
    done < "$1.sed"
    echo "}" >> junk/CheckSelf.awk.$$

    cat junk/``CheckSelf.awk.$$
    rm -f junk/CheckSelf.awk.$$
}

function ConvRule2Self()
{
    local FNAME="$1"
    local SNAME="$2"
    local TNAME="$3"
    
    fnn=$(tail -2 $FNAME|awk -F'\t' '{print NF}'|sort|uniq)
    >junk/CompareSelf.grules

    while read line 
    do
        echo "$line" |grep "key" &>/dev/null && continue
        >junk/$(basename $FNAME|awk -F'-' '{print $1}').subv
        >junk/$(basename $SNAME|awk -F'-' '{print $1}').subv

        > junk/SubV.txt
        echo "$line" | 
        awk -F'=' -v FN="$(basename $FNAME|awk -F'-' '{print $1}')" \
            -v OFS='=' -v SN="$(basename $SNAME|awk -F'-' '{print $1}')" \
            -v FNN="$fnn" '
        {
            print "KEY#"$0 >> "junk/SubV.txt";
            for (n=1;n<=NF;n++)
                {
                    if (index($n, FN))
                        {
                            split($n, Arr, /[+*-\/\|]/);
                            for(item in Arr)
                                {
                                    if (index(Arr[item], "$"))
                                        {
                                            print "1#"Arr[item] >> "junk/SubV.txt";
                                        }
                                }
                         }
                         else if (index($n, SN))
                             {
                                 split($n, Arr, /[+*-\/\|]/);
                                 for(item in Arr)
                                     {
                                         if (index(Arr[item], "$"))
                                             {
                                                 print "2#"Arr[item] >> "junk/SubV.txt";
                                             }
                                      }
                              }
                 }
                 CMD="Rules/SubV.sh "FN" "SN" "FNN"";
                 system(CMD);
                 #CMD|getline;
                 #close(CMD);
          }' 
    done < $TNAME

    while read line
    do
        line=$(echo ${line//$(basename $FNAME)|/})
        line=$(echo ${line//$(basename $SNAME)|/})
        echo $line
    done < junk/CompareSelf.grules > junk/CompareSelf.good

}


valS=""
function Conv2Self()
{
    local FNAME="$1"
    local SNAME="$2"
    local TNAME="$3"

    KeyStr=$(cat $TNAME|awk -F':' '$1=/key/{print $2}')
    FB=$(basename $FNAME | awk -F'-' '{print $1}')
    SB=$(basename $SNAME|awk -F'-' '{print $1}')
    eval $FB=
    eval $SB=

    for F in $FNAME $SNAME
    do
        CV=$(basename $F|awk -F'-' '{print $1}')

        #get key field
        for FF in $FB $SB
        do
            [ "$CV" != "$FF" ] && NCV="$FF"
        done

        > junk/$CV.jug
        > junk/WhileGet.txt
        echo $KeyStr |awk -F'[,]' -v SS="$CV" -v NSS="$NCV" -v JUGF="junk/$CV.jug" '
        {
            for (n=1;n<=NF;n++)
                {
                    if (index($n, SS) && index($n, NSS))
                        {
                            print $n > "junk/GetField.txt";
                        }
                    else if (index($n, SS) && !index($n, NSS))
                        {
                            match($n, /\|/);
                            print "\t"substr($n, RSTART+1, length($n)-RSTART) >> JUGF;
                        }
                }

                CMD="awk  -F= -v SS="SS" -f Rules/GetField.awk junk/GetField.txt";
                system(CMD)
                #CMD|getline;
                #close(CMD);
        }
        '

        valS=""
        while read line
        do
            [ "$valS" == "" ] && {
                valS="print $line"
                continue
            } 

            valS=$valS"\"|\""$line
        done < junk/WhileGet.txt

        eval $CV='$(echo $valS | tr -d 'print ')'
        eval "cat $F | awk -F'\t' '
        {
            $valS
        }
        '" > junk/$CV.comm
        
        JS=$(
            cat "junk/$CV.jug" | awk -F'\t' '
            {
                for (n=2;n<=NF;n++)
                    {
                        if (n==2)
                            {
                                JS=$n;
                            }
                        else
                            {
                                JS=JS"&&"$n
                            }
                    }
            }
            END {
                print JS;
            }
            '
        )

        if [ "$JS" != "" ];then
            eval "cat $F | awk -F'\t' -v OFS='\t' '{
            if ($JS)
                {
                    print \$0;
                }

            }'" > junk/$CV.ready
        else
            cp $F junk/$CV.ready
        fi
    done

    sort junk/$FB.comm > junk/$FB.comm.sort
    sort junk/$SB.comm > junk/$SB.comm.sort
    comm junk/$FB.comm.sort junk/$SB.comm.sort | awk -F'\t' '{if ($3 != ""){print $3}}' > junk/Compare.key
    
    FF=$(tail -2 junk/Compare.key|awk -F"|" '{print NF}'|sort -u)
    for F in $FNAME $SNAME
    do
        V=$(basename $F | awk -F'-' '{print $1}')

        > junk/$V.diff
        while read line
        do
            eval "
            cat $(echo $F|awk -F'-' '{print $1}').ready | awk -F'\t' -v OFS='\t' -v LINE='$line' '
            {
                if ( $(eval echo '$'$V) == LINE)
                    {
                        print LINE\"#\"\$0 >> \"junk/$V.diff\";
                    }
            }
            '
            "
        done < junk/Compare.key
    done

    join -t'#' junk/$(basename $FNAME | awk -F'-' '{print $1}').diff junk/$(basename $SNAME | awk -F'-' '{print $1}').diff > junk/Compare.diff
    ConvRule2Self $FNAME $SNAME $TNAME
}



function GenCompareAwk()
{
   cp Rules/CheckCompare.awk.temp junk/CheckCompare.awk.$$ 
   while read line
   do
        cat << EOF >> junk/CheckCompare.awk.$$
        
EOF
   done
}

function Self()
{
    local FNAME="$1"
    local SNAME="$2"
    local TNAME="$3"
    
    [ "$TNAME" != "" ] && FNAME="junk"


    #check file by file and field by field
    for FILE in $(ls "$FNAME/$TNAME")
    do
        FILE=$(basename $FILE)
        #get this file conf
        GetSelfRule "$FNAME/$FILE" "$SNAME"  > junk/$FILE.rules

        [ ! -s "junk/$FILE.rules" ] && echo -e "\033[31mWarning: $FNAME/$FILE have not configure rules conf,pls check.\033[0m"
        GenSelfAwk "junk/$FILE.rules" > "junk/CheckSelf.awk"
        rm -f junk/$FILE.rules

        cat $FNAME/$FILE |awk -F'\t' -v OFS='\t' -f junk/CheckSelf.awk
        exit
    done
}


function Compare()
{
    local FNAME="$1"
    local SNAME="$2"
    local TNAME="$3"
    
    for FILE1 in $(ls "$FNAME"/)
    do
        for FILE2 in $(ls "$SNAME"/)
        do
            GetCompareRule "$FNAME/$FILE1" "$SNAME/$FILE2" "$TNAME" > junk/Compare.rules
            [ ! -s "junk/Compare.rules" ] && continue
            FormatFile "$FNAME/$FILE1" > junk/$FNAME-$FILE1
            FormatFile "$SNAME/$FILE2" > junk/$SNAME-$FILE2
            Conv2Self junk/$FNAME-$FILE1 junk/$SNAME-$FILE2 "junk/Compare.rules"
            $QADIR/RulesMake.sh junk/Compare.diff junk/CompareSelf.good > junk/Compare.rules
            Self junk/Compare.diff junk/Compare.rules "Compare.diff"
        done
    done
}


[ -d "$FNAME" -a -f "$SNAME" -a $# -eq 2 ] && Self "$FNAME" "$SNAME"

[ -d "$FNAME" -a -d "$SNAME" -a  -f "$TNAME" -a $# -eq 3 ] && Compare "$FNAME" "$SNAME" "$TNAME"
