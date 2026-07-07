#!/bin/sh
set -eux

API_BASE='https://example.net/myroom/_design/queries/_view/by_ts?include_docs=true'

plot_range() {
    endpoint="$API_BASE&startkey=$1&endkey=$2"
    out="$3"

    tsv="$(mktemp)"
    curl "$endpoint" | jq -r '.rows[].doc | [.ts, .t, .h, .hi] | @tsv' > "$tsv"

    gnuplot <<-EOF
		set term png
		set output '$out'
		set key tmargin center horizontal
		set grid

		set autoscale xfixmin
		set timefmt '%s'
		set xdata time
		set xtics rotate by 45 right font ',10'
		set format x '%m/%d %H:%M'

		set ylabel 'temp'
		set ytics nomirror

		set y2label 'hum' rotate by -90
		set y2tics

		offset = 3600 * 9
		plot '$tsv' using (\$1 + offset):2 axis x1y1 with lines title 'temp', \
		     ''     using (\$1 + offset):3 axis x1y2 with lines title 'hum'
	EOF

    rm "$tsv"
}

base="$(dirname $0)"
now="$(date +%s)"
plot_range $((now - 3600 * 6))      "$now" "$base"/pub/myroom_6h.png
plot_range $((now - 3600 * 24))     "$now" "$base"/pub/myroom_1d.png
plot_range $((now - 3600 * 24 * 3)) "$now" "$base"/pub/myroom_3d.png
