#!/bin/bash


data_acquisition(){
  pid=`cat $1/status | grep '^Pid' | awk '{print $2}'`
  fd0=`readlink $1/fd/0 | grep -v null | sed -r 's/\/dev\///'`
  if [ -z "$fd0" ]
    then
      fd0="?"
  fi
  name=`cat $1/status | grep '^Name' | awk '{print $2}'`
  status=`cat $1/status | grep '^State' | awk '{print $2}'`
cpu_time_min=`cat $1/stat | awk '{print int((($14+$15) / 100)/60)}'`
cpu_time_sec=`cat $1/stat | awk '{print int((($14+$15) / 100)%60)}'`
  s=`cat $1/cmdline | tr -d '\0'`
  if ! [ -z "$s" ]
    then
      printf "%5s %-8s %-3s %4d:%02d  %s\n" "$pid" "$fd0" "$status" "$cpu_time_min" "$cpu_time_sec"  "$s" 1>> /tmp/1
    else
      printf "%5s %-8s %-3s %4d:%02d  %s\n" "$pid" "$fd0" "$status" "$cpu_time_min" "$cpu_time_sec" "[$name]" 1>> /tmp/1
  fi
}





printf "%5s %-8s %-3s %7s %10s %s\n" `echo PID` `echo TTY` `echo STAT` `echo TIME` `echo COMMAND` 1>> /tmp/1

for proc in `ls /proc | egrep ^[0-9]+$ | sort -n`
  do
    [ -d "/proc/$proc" ]  && data_acquisition /proc/$proc
done

cat /tmp/1
rm -r /tmp/1
