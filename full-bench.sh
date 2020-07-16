#!/bin/bash
set -e

if ! [ ${JDK+set} ]; then
	echo '$JDK is not set'
	exit 1
fi

B=$(dirname $0)
EXAMPLE_BASE=$B/..

N_CHECKPOINT=10
N_RESTORE=5

EXAMPLES=(
	spring-boot
	micronaut
	quarkus
	xml-transform
)

declare -A JAR=(
	[spring-boot]=target/spring-boot-0.0.1-SNAPSHOT.jar
	[micronaut]=build/libs/example-0.1-all.jar
	[quarkus]=target/example-quarkus-1.0-SNAPSHOT-runner.jar
	[xml-transform]=target/spring-boot-0.0.1-SNAPSHOT.jar
)

declare -A STARTED=(
	[spring-boot]="Started Application"
	[micronaut]="Startup completed"
	[quarkus]="Installed features"
	[xml-transform]="Started Application"
)

path() {
	echo $EXAMPLE_BASE/example-$e
}

bench() {
	local BENCH="$B/bench.sh"
	case $e in
	spring-boot)   $BENCH http://localhost:8080 ;;
	micronaut)     $BENCH http://localhost:8080/hello/test ;;
	quarkus)       $BENCH http://localhost:8080/hello ;;
	xml-transform) $BENCH \
		-H "Content-type: text/plain" \
		"http://localhost:8080/transform POST < $(path)/example.xml"
		;;
	esac
}

prepare() {
	case $e in
	xml-transform)
		cp $(path)/default.xsl .
	esac
}

cstart() {
	case $e in
	spring-boot | xml-transform)
		awk 'match($0, /JVM running for ([0-9.]+)/, m) { print m[1] * 1000 }' "$@"
		;;
	micronaut)
		awk 'match($0, /Startup completed in ([0-9]+)ms/, m) { print m[1] }' "$@"
		;;
	quarkus)
		awk 'match($0, /started in ([0-9.]+)s/, m) { print m[1] * 1000}' "$@"
		;;
	esac
}


collect() {
	for e in ${EXAMPLES[@]}; do
		mkdir -p $e
		prepare

		for i in $(seq $N_CHECKPOINT); do

			P=$($B/start-bg.sh \
			-s "${STARTED[$e]}" \
			-e exitcode \
			-l $e/log.c.$i \
			$JDK/bin/java \
			  -Zcheckpoint:cr \
			  -XX:+UnlockDiagnosticVMOptions \
			  -XX:+CRTraceStartupTime \
			  -Djdk.crac.trace-startup-time=true \
			  -jar $(path)/${JAR[$e]})

			bench | tee /dev/stderr > $e/c.$i
			$JDK/bin/jcmd $P JDK.checkpoint
			[ 137 = $($B/read-exitcode.sh exitcode) ]

			rm -f cr/timens-0.img

			for j in $(seq $N_RESTORE); do
				P=$($B/start-bg.sh \
				  -s "restore-finish" \
				  -l $e/log.r.$i.$j \
				  bash -c "$JDK/lib/javatime ; exec $JDK/bin/java -Zrestore:cr")

				bench | tee /dev/stderr > $e/r.$i.$j
				kill $P
				sleep 5
			done
		done
	done
}

dostat() {
	awk '{ print $1 }' $1 | paste - \
		<(for i in $(seq $(wc -l < $1)); do
			awk -v i=$i 'FNR == i { print $2 }' "$@" | $B/stat.awk -v target=avg
		done)
}

parse() {
	for e in ${EXAMPLES[@]}; do
		p=$(mktemp)
		for i in $(seq $N_CHECKPOINT); do
			dostat $e/r.$i.* > $p.$i
		done
		paste <(dostat $e/c.*) <(dostat $p.*) | \
			awk '{ printf "%6s %6.02f %6.02f\n", $1, $2, $4 }' > $e.data
		rm $p $p.*
	done

	for e in ${EXAMPLES[@]}; do
		( echo $e;
		cstart $e/log.c.* | $B/stat.awk -v fmt="%d" -v target=avg
		for i in $(seq $N_CHECKPOINT); do
			$B/sel.awk -v from=prestart -v to=restore-finish $e/log.r.$i.* | $B/stat.awk -v target=avg
		done ) | paste -s | awk '{ printf "%16s %6d %6d\n", $1, $2, $3 * 1000 }'
	done > startup.data
}

"$@"
