#!/bin/sh

exitcode=$1

e=$(head $exitcode 2>/dev/null)
while [ ! $e ]; do
	sleep 0.5
	e=$(head $exitcode 2>/dev/null)
done
echo $e
