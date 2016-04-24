#!/bin/bash

# default timeout is 60sec
export TIMEOUT=${TIMEOUT:-60}
export NETBOMB=${NETBOMB:-"iperf -c iperf.scottlinux.com -t ${TIMEOUT} -i 1 -p 5201 -u"}

help() {
  echo "WARNING: IT IS NOT GUARANTEED THAT YOUR SYSTEM/CONTAINERS WILL SURVIVE THIS KILLER TESTING! DO NOT USE THIS IMAGE UNLESS YOU REALLY KNOW WHAT ARE YOU DOING!"
  echo "Danger Docker tests are included in this image, such as: cpubomb, membomb, netbomb, forkbomb, ..."
  echo "Use 'all' or name of the particular test, e.g. docker run --rm -ti monitoringartist/docker-kill cpubomb"
}
export -f help

forkbomb() {
  echo 'forkbomb()'
  echo 'Test: classic bash shell fork bomb'
  :(){ :|:& };:
}
export -f forkbomb

cpubomb() {
  echo 'cpubomb()'
  echo 'Test: excessive CPU utilization - one proces per processor with empty cycles'
  top -b -n${TIMEOUT} -d1 | grep "^CPU:" &
  #top -b -n${TIMEOUT} -d1 | grep "^Load average:" &      
  (
    pids=""
    cpus=$(getconf _NPROCESSORS_ONLN)
    trap 'for p in $pids; do kill $p; done' 0
    for ((i=0;i<cpus;i++)); do while : ; do : ; done & pids="$pids $!"; done
    sleep ${TIMEOUT}
  )
}
export -f cpubomb

membomb() {
  echo 'membomb()'
  echo 'Test: excessive memory utilization - bash variable with RAM+Swap size'
  top -b -n${TIMEOUT} -d1 | grep "^Mem:" & 
  /membomb.bin
}
export -f membomb

netbomb() {
  echo 'netbomb()'
  echo 'Test: excessive network utilization - iperf against public iperf server'  
  $($NETBOMB)
}
export -f netbomb

die() {
  echo 'die()'
  echo 'Test: exit container with exit code 1'
  exit 1
}
export -f die

chaosmonkey() {
  echo 'chaosmonkey()'
  echo 'Test: stop random container'
  # TODO
}
export -f chaosmonkey

passwords() {
  echo 'passwords()'
  echo 'Test: read password hashes from host system'
  # TODO
}
export -f chaosmonkey

kernelpanic() {
  echo 'kernelpanic()'
  echo c >/proc/sysrq-trigger
}
export -f kernelpanic

if [ "$1" == "all" ]; then
  timeout -t ${TIMEOUT} -s KILL bash -c cpubomb
  timeout -t ${TIMEOUT} -s KILL bash -c membomb
  timeout -t ${TIMEOUT} -s KILL bash -c netbomb
  timeout -t ${TIMEOUT} -s KILL bash -c forkbomb
else 
  timeout -t ${TIMEOUT} -s KILL bash -c $@
fi
