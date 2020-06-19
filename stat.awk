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
	fmt = "%.06f"
	printf "min "fmt" max "fmt" avg "fmt" mean(1) "fmt"\n", t[1], t[n], mean[0], mean[1]
}

