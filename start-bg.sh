#!/bin/bash

tries=10

while getopts e:s:l:t: name; do
	case $name in
		e) exitcode="$OPTARG" ;;
		s) started="$OPTARG" ;;
		l) log="$OPTARG" ;;
		t) tries="$OPTARG" ;;
		?) printf "Usage: %s: [−s started-pattern] [-e exit-code-file] [ -t timeout-sec ] CMD\n" $0
		   exit 2;;
	esac
done
shift $(($OPTIND - 1))

pidfile=$$.pid
if [ -z $log ]; then
	log=$$.log
	clearlog=1
fi

cleanup() {
	rm -f $pidfile
	[ $clearlog ] && rm -f $log
}
trap cleanup EXIT INT

if [ z${exitcode+set} = zset ]; then
	echo -n > $exitcode
fi

echo > $log
(
	"$@" 2>&1 & echo $! > $pidfile
	if [ z${exitcode+set} = zset ]; then
		wait $!
		echo $? >> $exitcode
	fi
) | tee $log >&2 &

if [ z${started+set} = zset ]; then
	while [ $tries -gt 0 ]; do
		grep -q "$started" $log && break
		sleep 1
		tries=$(($tries - 1))
	done
fi

grep -q "$started" $log || exit 1

cat $pidfile
