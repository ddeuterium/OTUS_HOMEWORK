#!/bin/bash
#FILE=/var/log/access.log
FILE=/tmp/access.log
FLAG=/tmp/den
FLAG1=/tmp/den.oldscan
if [ -f $FLAG ]; then
    echo Error: Script working, exit..
    exit 1
fi

if [ $# -ne 2 ]; then
    echo Error: not enough arguments, should be so:
    echo ./script 10 15
    echo first - top of ip
    echo second - top of queries
    rm -rf $FLAG
    exit 1
fi

if [ -f $FLAG1 ]; then
    STR_SCANEDold1=`tail -n1 $FLAG1`
    STR_SCANEDold2=`wc -l $FILE| awk '{print $1}'`
    echo $STR_SCANEDold2 > $FLAG1
    STR_SCANED=`echo $STR_SCANEDold2 - $STR_SCANEDold1 | bc`
#    echo $STR_SCANED
else
    STR_SCANED=`wc -l $FILE| awk '{print $1}'`
    echo $STR_SCANED > $FLAG1
fi



echo "TOP $2 of URLs" >> $FLAG
tail $FILE -n $STR_SCANED | awk '{print $1" "$7" -"$9}' | grep -e "\-200$" | awk '{print $2}' | sort -n | uniq -c | sort -gr | head -n $2 >> $FLAG
echo "TOP $1 of IPs" >> $FLAG
tail $FILE  -n $STR_SCANED | awk '{print $1" "$7" -"$9}' | grep -e "\-200$" |  awk '{print $1}' | sort -n | uniq -c | sort -gr | head -n $1 >> $FLAG
echo "Count of error codes" >> $FLAG
tail $FILE  -n $STR_SCANED | awk '{print $9}' | grep -v "200$" | grep -v "301$" | sed "s/\"-\"/400/g" | sort -n | uniq -c >> $FLAG
echo "Errors" >> $FLAG
tail $FILE -n $STR_SCANED | grep -v "200" | grep -v "301" >> $FLAG

cat $FLAG | mail aaa@aaa.sss -s 'OTUS_HW_5'
rm -rf $FLAG

