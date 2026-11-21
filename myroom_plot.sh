#!/bin/sh
set -eux

# CouchDB view endpoint: room sensor time series (ts, t, h, hi)
API_BASE='https://example.net/myroom/_design/queries/_view/by_ts?include_docs=true'

# Generate one plot for [startkey, endkey].
# Args: startkey endkey output_png temp_ma_window hum_ma_window
plot_range() {
    endpoint="$API_BASE&startkey=$1&endkey=$2"
    out="$3"      # output PNG path
    w_t="$4"      # temp moving-average window (samples, centered)
    w_h="$5"      # hum  moving-average window (samples, centered)

    tsv="$(mktemp)"     # raw rows: ts, t, h, hi
    ma_tsv="$(mktemp)"  # computed rows: ts, t, h, t_ma, h_ma
    curl "$endpoint" | jq -r '.rows[].doc | [.ts, .t, .h, .hi] | @tsv' > "$tsv"

    gnuplot <<-EOF
		# === output instruction / style ===
		set term pngcairo size 1100,650 font "CMU Serif,12"
		set output '$out'
		set key tmargin center horizontal font "CMU Serif,18"
		set grid
		set border lw 2
		set colorsequence podo  # colorblind-friendly palette

		# --- margins: CMU fontsize fitting ---
		set lmargin 18
		set rmargin 18
		set bmargin 5

    # === MA (Moving Average, smoothing) calculation ===
		# --- Load data into arrays ---
		stats '$tsv' using 1 nooutput
		N = STATS_records
		array TS[N]  # time (epoch seconds)
		array T[N]   # temperature [C]
		array H[N]   # humidity [%]
		i = 0
		stats '$tsv' using (i=i+1, TS[i]=\$1, T[i]=\$2, H[i]=\$3, 0) nooutput

		# --- Moving-Average windows (sample count, centered: +/- half) [windows size defined by graph time range] ---
		w_t = $w_t
		w_h = $w_h
		half_t = int(w_t / 2)
		half_h = int(w_h / 2)

		# --- Y ranges include raw-data and MA-values; Y width becomes 1.2x observed width ---
		tmin = 1e30
		tmax = -1e30
		hmin = 1e30
		hmax = -1e30
		# Track first index of raw min/max for labels
		rtmin = 1e30; rtmax = -1e30; rhmin = 1e30; rhmax = -1e30
		rtmin_i = 0; rtmax_i = 0; rhmin_i = 0; rhmax_i = 0

		# --- Sliding-window ---
		tsum = 0.0; tcnt = 0; lo_t = 1; hi_t = 0
		hsum = 0.0; hcnt = 0; lo_h = 1; hi_h = 0

		set print '$ma_tsv'
		do for [j=1:N] {
			# --- temp MA: centered window [j-half_t, j+half_t] ---
			new_lo_t = (j - half_t < 1) ? 1 : (j - half_t)
			new_hi_t = (j + half_t > N) ? N : (j + half_t)
			while (hi_t < new_hi_t) {
				hi_t = hi_t + 1
				if (T[hi_t] == T[hi_t]) { tsum = tsum + T[hi_t]; tcnt = tcnt + 1 }
			}
			while (lo_t < new_lo_t) {
				if (T[lo_t] == T[lo_t]) { tsum = tsum - T[lo_t]; tcnt = tcnt - 1 }
				lo_t = lo_t + 1
			}
			while (lo_t > new_lo_t) {
				lo_t = lo_t - 1
				if (T[lo_t] == T[lo_t]) { tsum = tsum + T[lo_t]; tcnt = tcnt + 1 }
			}
			while (hi_t > new_hi_t) {
				if (T[hi_t] == T[hi_t]) { tsum = tsum - T[hi_t]; tcnt = tcnt - 1 }
				hi_t = hi_t - 1
			}
			tma = (tcnt > 0) ? tsum / tcnt : NaN

			# --- hum MA: centered window [j-half_h, j+half_h] ---
			new_lo_h = (j - half_h < 1) ? 1 : (j - half_h)
			new_hi_h = (j + half_h > N) ? N : (j + half_h)
			while (hi_h < new_hi_h) {
				hi_h = hi_h + 1
				if (H[hi_h] == H[hi_h]) { hsum = hsum + H[hi_h]; hcnt = hcnt + 1 }
			}
			while (lo_h < new_lo_h) {
				if (H[lo_h] == H[lo_h]) { hsum = hsum - H[lo_h]; hcnt = hcnt - 1 }
				lo_h = lo_h + 1
			}
			while (lo_h > new_lo_h) {
				lo_h = lo_h - 1
				if (H[lo_h] == H[lo_h]) { hsum = hsum + H[lo_h]; hcnt = hcnt + 1 }
			}
			while (hi_h > new_hi_h) {
				if (H[hi_h] == H[hi_h]) { hsum = hsum - H[hi_h]; hcnt = hcnt - 1 }
				hi_h = hi_h - 1
			}
			hma = (hcnt > 0) ? hsum / hcnt : NaN

			# --- Track y ranges and first raw min/max locations ---
			if (T[j] == T[j]) {
				if (T[j] < tmin) { tmin = T[j] }
				if (T[j] > tmax) { tmax = T[j] }
				if (T[j] < rtmin) { rtmin = T[j]; rtmin_i = j }
				if (T[j] > rtmax) { rtmax = T[j]; rtmax_i = j }
			}
			if (tma == tma) {
				if (tma < tmin) { tmin = tma }
				if (tma > tmax) { tmax = tma }
			}
			if (H[j] == H[j]) {
				if (H[j] < hmin) { hmin = H[j] }
				if (H[j] > hmax) { hmax = H[j] }
				if (H[j] < rhmin) { rhmin = H[j]; rhmin_i = j }
				if (H[j] > rhmax) { rhmax = H[j]; rhmax_i = j }
			}
			if (hma == hma) {
				if (hma < hmin) { hmin = hma }
				if (hma > hmax) { hmax = hma }
			}

			# --- Output: ts, raw temp, raw hum, temp MA, hum MA ---
			print sprintf("%.0f\t%g\t%g\t%g\t%g", TS[j], T[j], H[j], tma, hma)
		}
		set print

		# --- Y ranges: 1.2x of observed raw+MA width (0.1 padding each side) ---
		tw = tmax - tmin
		hw = hmax - hmin
		tpad = (tw > 0) ? tw * 0.1 : 0.5
		hpad = (hw > 0) ? hw * 0.1 : 0.5
		set yrange [tmin - tpad : tmax + tpad]
		set y2range [hmin - hpad : hmax + hpad]

		# --- Axes / labels ---
		set autoscale xfixmin
		set timefmt '%s'
		set xdata time
		set xtics rotate by 45 right font "CMU Typewriter Text,14"
		set format x '%m/%d %H:%M'

		set ylabel 'temp [℃]' font "CMU Serif,29" offset -6,0
		set ytics nomirror font "CMU Serif,25"
		set format y "%.1f"

		set y2label 'hum [%]' rotate by -90 font "CMU Serif,29" offset 6,0
		set y2tics font "CMU Serif,25"
		set format y2 "%.1f"

    # === Generate reptesentative (max/min) points ===
		# --- Choose points: 30 per pane (without max/min points) ---
		step = (N > 30) ? int(ceil(N / 30.0)) : 1
		# JST offset for display
		offset = 3600 * 9
		# Vertical dotted lines at JST midnight (00:00)
		day = 86400
		t0 = TS[1] + offset
		t1 = TS[N] + offset
		first_midnight = int(ceil(t0 / day)) * day
		set for [d=first_midnight:t1:day] arrow from d, graph 0 to d, graph 1 nohead dt (2,2) lt 1 lw 2

		# --- Label first raw min/max points (small font, same color as series) ---
		if (rtmax_i > 0) { set label 1 "max temp" at (TS[rtmax_i] + offset), rtmax font "CMU Serif,11" tc lt 2 offset 0.5,0.5 point pt 18 ps 1 lt 2 front }
		if (rtmin_i > 0) { set label 2 "min temp" at (TS[rtmin_i] + offset), rtmin font "CMU Serif,11" tc lt 2 offset 0.5,-0.5 point pt 18 ps 1 lt 2 front }
		if (rhmax_i > 0) { set label 3 "max hum"  at (TS[rhmax_i] + offset), second rhmax font "CMU Serif,11" tc lt 3 offset 0.5,0.5 point pt 18 ps 1 lt 3 front }
		if (rhmin_i > 0) { set label 4 "min hum"  at (TS[rhmin_i] + offset), second rhmin font "CMU Serif,11" tc lt 3 offset 0.5,-0.5 point pt 18 ps 1 lt 3 front }

		# --- Plot: raw data as representative points; MA as solid lines ---
		plot '$ma_tsv' every step using (\$1 + offset):2 axis x1y1 with points pt 18 ps 1 lt 2 title 'temp', \
		     ''        using (\$1 + offset):4 axis x1y1 with lines dashtype 1 lw 2 lt 2 title 'temp MA', \
		     ''        every step using (\$1 + offset):3 axis x1y2 with points pt 18 ps 1 lt 3 title 'hum', \
		     ''        using (\$1 + offset):5 axis x1y2 with lines dashtype 1 lw 2 lt 3 title 'hum MA'
	EOF

    rm "$tsv" "$ma_tsv"
}

# Time ranges relative to now; MA windows scale by range ratio (6h baseline: temp 30, hum 108)
base="$(dirname $0)"
now="$(date +%s)"
plot_range $((now - 3600 * 6))      "$now" "$base"/pub/plot_myroom_6h.png 30 108
plot_range $((now - 3600 * 24))     "$now" "$base"/pub/plot_myroom_1d.png 120 432
plot_range $((now - 3600 * 24 * 3)) "$now" "$base"/pub/plot_myroom_3d.png 360 1296
