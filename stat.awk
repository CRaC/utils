#!/usr/bin/awk -f

{
	t[++s] = $1
}

END {
	if (!fmt)
		fmt = "%.06f"

	n = asort(t)
	M = 2 < n ? 1 : 0;
	for (m = 0; m <= M; ++m) {
		for (i = 1 + m; i <= n - m; ++i)  {
			mean[m] += t[i]
		}
		mean[m] /= n - 2 * m
	}

	stat["min"]  = t[1]
	stat["max"]  = t[n]
	stat["avg"]  = mean[0]
	stat["mean"] = mean[1]
	if (target)
		printf fmt"\n",  stat[target]
	else
		for (i in stat)
			printf "%6s "fmt"\n", i, stat[i]
}
