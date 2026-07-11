#!/bin/sh
set -eux

endpoint='https://example.net/mass/_design/queries/_view/by_ts?include_docs=true'

out="$(dirname $0)"/pub/plot_mass.png

tsv="$(mktemp)"
curl "$endpoint" | jq -r '.rows[].doc | [.ts, .mass, .fat] | @tsv' > "$tsv"

gnuplot <<-EOF
	set term png
	set output '$out'
	set key tmargin center horizontal
	set grid

	set autoscale xfixmin
	set timefmt '%s'
	set xdata time
	set xtics rotate by 45 right font ',10'
	set format x '%m/%d'

	set ylabel 'mass'
	set ytics nomirror

	set y2label 'fat' rotate by -90
	set y2tics

	offset = 3600 * 9
	plot '$tsv' using (\$1 + offset):2 axis x1y1 with lines title 'mass', \
	     ''     using (\$1 + offset):3 axis x1y2 with lines title 'fat'
EOF

rm "$tsv"
