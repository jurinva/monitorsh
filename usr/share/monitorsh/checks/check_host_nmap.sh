#!/bin/sh
NMAP="/usr/bin/nmap -sP"
TMP=/tmp/nmap_ping.$$
CHECK="Nmap Ping host $1"

results_exit()
{
  rm -f $TMP
  echo "$CHECK: ${2}"
  return $1
}

$NMAP $1 > $TMP || results_exit 255 "Could not execute $NMAP"

grep "Host seems down" $TMP
[ $? -eq 0 ] && results_exit 2 "CRITICAL"

grep "Host is up" $TMP
[ $? -eq 0 ] && results_exit 0 "Ok"

