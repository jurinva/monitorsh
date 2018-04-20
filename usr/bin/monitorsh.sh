#!/bin/bash

#<config>
if [ -e /etc/monitorsh/monitorsh.cfg ]; then
  cfgfile=/etc/monitor/monitor.cfg
  else if [ -e /etc/monitor.cfg ]; then cfgfile=/etc/monitor.cfg; fi
fi
#echo "cfgfile= $cfgfile"

while read propline ; do
  # ignore comment lines
  echo "$propline" | grep "^#" >/dev/null 2>&1 && continue
  # if not empty, set the property using declare
  [ ! -z "$propline" ] && declare $propline
done < /$cfgfile
#~/monitor/etc/monitor/monitor.cfg

#</config>


#<nagiosql_modul>

#<nagiosql_config>

mysqlhost="192.168.255.255"
mysqldb="db_nagiosql"
mysqluser="root"
mysqlpasswd="root"
hostsquery="select concat(address,';',host_name,';',check_command) from tbl_host where address like '192.168.27%' and hostgroups=1 or hostgroups=16 or hostgroups=22 or hostgroups=0"
checksquery="select replace(command_line,' ',';') from tbl_checkcommand where id="

#</nagiosql_config>

function nsqlcommand {
  for commands in `echo "$checksquery$1" | mysql -s -h$mysqlhost -D$mysqldb -u$mysqluser -p$mysqlpasswd`
    do
      echo $commands | cut -d";" -f1 | cut -d" " -f1 | cut -d"/" -f2
  done
}

function nsqlhost {
  echo "$hostsquery" | mysql -s -h$mysqlhost -D$mysqldb -u$mysqluser -p$mysqlpasswd | sort
}

#function nsql


#selecthost

#</nagiosql_modul>

#<xml_modul>

function xmlread {
  xmlarray=0
  while read line
  do
    name=`echo $line | sed -n -e 's/.*<name>\(.*\)<\/name>.*/\1/p'`
    ip=`echo $line | sed -n -e 's/.*<ip>\(.*\)<\/ip>.*/\1/p'`
    command=`echo $line | sed -n -e 's/.*<command>\(.*\)<\/command>.*/\1/p'`
    host=`echo $host $name $ip $command`
    if [ `echo $host | wc -w` -eq 3 ]; then name[$xmlarray]=`echo $host | cut -d" " -f1`; ip[$xmlarray]=`echo $host | cut -d" " -f2`; command[$xmlarray]=`echo $host | cut -d" " -f3`;host=''; fi
  xmlarray=$(($xmlarray+1))
  done < $confdir/$conffile
}

function xmlwrite {
  echo "<hosts>" > $confdir/$conffile
  for hosts in `nsqlhost`
    do
      echo $I
      host_name=`echo $hosts | cut -d";" -f2`
      ip=`echo $hosts | cut -d";" -f1`
      check_command_id=`echo $hosts | cut -d";" -f3`
      command=`nsqlcommand $check_command_id`
      echo "<host>" >> $confdir/$conffile
      echo "<name>$host_name</name>" >> $confdir/$conffile
      echo "<ip>$ip</ip>" >> $confdir/$conffile
      echo "<command>$command</command>" >> $confdir/$conffile
      echo "</host>" >> $confdir/$conffile
  done
  echo "<hosts>" >> $confdir/$conffile
}

#</xml_modul>

function monexec {
  xmlread
  > $tmpdir/$logfile
  I=0
  while [ $I -le $xmlarray ]
  do
    command=`echo "${command[$I]} ${ip[$I]}"`
    case $log in
      term) if [ `echo $command | wc -c` -gt 1 ]; then result=`$prefix/$command | cut -d" " -f2`; if [ $result = OK ]; then echo -e "\e[00;42m${name[$I]} - ${ip[$I]} - OK\e[00m"; else echo -e "\e[00;41m${name[$I]} - ${ip[$I]} - CRITICAL\e[00m"; fi ; fi;;
      *) if [ `echo $command | wc -c` -gt 1 ]; then result=`$prefix/$command | cut -d" " -f2`; if [ $result = OK ]; then echo -e "OK-${name[$I]}-${ip[$I]}" >> $tmpdir/$logfile; else echo -e "CRITICAL-${name[$I]}-${ip[$I]}" >> $tmpdir/$logfile; fi ; fi;;
    esac
    I=$(($I+1))
  done
}

function main {
  case $action in
    r) monexec;;
    w) xmlwrite;;
  esac
}

while getopts "a:c:l:s:h:v" arg
do
  case $arg in
    a) action=$OPTARG;; #r - read, w - write
    c) conffile="$OPTARG.xml"; logfile="$OPTARG.log";; #configuration name
    l) log=$OPTARG;; #loggin destination
    s) dsource=$OPTARG;; #nsql - nagiosql(mysql), xml - xml -file
    h) echo Using: $0 [-q] [-h] [-e scriptfile] FILES...;
       exit;;
  esac
done

main
