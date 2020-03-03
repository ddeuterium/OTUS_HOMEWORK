#!/bin/bash
FILE=/tmp/access.log
FLAG=/tmp/den
FLAG1=/tmp/den.oldscan

if [ -f $FLAG ]; then
    echo Error: The script is running right now...  exit...
    exit 1
fi

if [ $# -ne 2 ]; then
    echo not enough arguments. Please enter the arguments like on the example below:
    echo ./access_log_analyzer.sh 10 15
    echo First - Top 10 of the IPs
    echo Second - Top 15 of the requested URLs
    rm -rf $FLAG
    exit 1
fi

if [ -f $FLAG1 ]; then
    STR_SCANEDold1=`tail -n1 $FLAG1`
    STR_SCANEDold2=`wc -l $FILE| awk '{print $1}'`
    echo $STR_SCANEDold2 > $FLAG1
    STR_SCANED=`echo $STR_SCANEDold2 - $STR_SCANEDold1 | bc`

else
    STR_SCANED=`wc -l $FILE| awk '{print $1}'`
    echo $STR_SCANED > $FLAG1
fi



echo "Top $2 of the requested URLs" >> $FLAG
tail $FILE -n $STR_SCANED | awk '{print $1" "$7" -"$9}' | grep -e "\-200$" | awk '{print $2}' | sort -n | uniq -c | sort -gr | head -n $2 >> $FLAG
echo "Top $1 of the IPs" >> $FLAG
tail $FILE  -n $STR_SCANED | awk '{print $1" "$7" -"$9}' | grep -e "\-200$" |  awk '{print $1}' | sort -n | uniq -c | sort -gr | head -n $1 >> $FLAG
echo "Count of the error response status codes" >> $FLAG
tail $FILE  -n $STR_SCANED | awk '{print $9}' | grep -v "200$" | grep -v "301$" | sed "s/\"-\"/400/g" | sort -n | uniq -c >> $FLAG
echo "Errors" >> $FLAG
tail $FILE -n $STR_SCANED | grep -v "200" | grep -v "301" >> $FLAG

cat $FLAG | mail aaa@aaa.sss -s 'OTUS_HW_6'
rm -rf $FLAG

