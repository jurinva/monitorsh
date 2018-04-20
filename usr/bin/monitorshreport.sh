#!/bin/bash

while read propline ; do
   # ignore comment lines
   echo "$propline" | grep "^#" >/dev/null 2>&1 && continue
   # if not empty, set the property using declare
   [ ! -z "$propline" ] && declare $propline
done < /etc/monitor/monitor.cfg

clear
if [ -f "$sounddir/welcome.wav" ]; then 
  mplayer $sounddir/welcome.wav &
fi
STATUS=OK
while true
do
> $tmpdir/monitorsh.log
$bindir/monitorsh.sh -a r -c somename -l logfile

#echo report
OKSP=' '
YYYSP=' '
while [ `echo $OKSP | wc -c` -lt 79 ]
  do 
    OKSP="$OKSP."
  done

OK=`cat $tmpdir/monitorsh.log | grep CRITICAL | wc -l`
if [ $OK -eq 0 ]; then echo -e "\e[00;42m$OKSP OK\e[00m"; fi

for Y in `cat $tmpdir/monitorsh.log | grep CRITICAL`
  do
    YSP=`echo $Y | wc -c`
    YYSP=$((82-$YSP))
    while [ `echo $YYYSP | wc -c` -lt $YYSP ]
      do
        YYYSP="$YYYSP."
      done
    echo -e "\e[00;41m$Y $YYYSP\e[00m"
  done

negativefilenamenumber=`let R=$RANDOM%10; echo $R`


if [ $STATUS = OK -a `cat $tmpdir/monitorsh.log | grep CRITICAL | wc -l` -gt 0 ]; then mplayer $sounddir/`echo "n$negativefilenamenumber.wav"` &>/dev/null; STATUS=CRITICAL; fi
if [ $STATUS = CRITICAL -a `cat $tmpdir/monitorsh.log | grep CRITICAL | wc -l` -eq 0 ]; then mplayer $sounddir/`echo "p$negativefilenamenumber.wav"` &>/dev/null; STATUS=OK; fi

#killall -9 monitor.sh
sleep 5

done
