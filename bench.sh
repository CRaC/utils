#!/bin/sh

REQS=(200 1000 2000 5000 10000 20000 40000 60000 80000 100000)

URL=$1

vtable() {
	awk -v "REQS=${REQS[*]}" '
	BEGIN {
		split(REQS, reqs)
	}
	/Elapsed time:/ { 
		++n
		t[n] = t[n - 1] + $3
		printf "%6d %6.2f\n", reqs[n], t[n]
	}'
}

ITERS=$(printf "%s\n" ${REQS[@]} | awk '{ print $1 - p; p = $1 }')
for i in $ITERS; do 
	siege -c 1 -r $i -b $URL 2>&1 >/dev/null 
done | vtable
