#!/usr/bin/awk -f 

$1 != "STARTUPTIME" {
       next
}
from == $3 {
	f = $2
}
to == $3 {
	print ($2 - f) / (10**9)
}
