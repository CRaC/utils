#!/usr/bin/awk -f

{ 
	t[++s] = $1
}

END {
	n = asort(t)
	for (m = 0; m <= 1; ++m) {
		for (i = 1 + m; i <= n - m; ++i)  {
			mean[m] += t[i]
		}
		mean[m] /= n - 2 * m
	}

	stat["min"]  = t[1]
	stat["max"]  = t[n]
	stat["avg"]  = mean[0]
	stat["mean"] = mean[1]
	for (i in stat)
		printf "%6s %.06f\n", i, stat[i]
}
