#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Runs nginx and ffmpeg as two background processes in the same container.
# If either one dies, the whole container exits (non-zero) so an orchestrator
# (docker-compose `restart: unless-stopped`, k8s, etc.) can restart it cleanly
# instead of silently limping along with only half the pipeline working.
# ---------------------------------------------------------------------------
set -euo pipefail

rm -f /out/*.m4s /out/*.mp4 /out/*.m3u8

# Mathematical sequence calculation: current epoch / hls_time (2 seconds).
# Keeps segment numbering continuous/predictable across restarts instead of
# always resetting to 0.
START_NUM=$(( $(date +%s) / 2 ))

# `daemon off;` keeps nginx in the foreground so we can track its PID and
# have it die with the container instead of forking away from us.
nginx -g "daemon off;" &
NGINX_PID=$!

ffmpeg -y \
  -use_wallclock_as_timestamps 1 \
  -i "udp://0.0.0.0:1234?overrun_nonfatal=1&fifo_size=5000000" \
  -map 0:v:0 -map 0:a:0 \
  -vf "drawtext=fontfile=/usr/share/fonts/dejavu/DejaVuSans.ttf:text='$TEXT UTC %{localtime\:%Y-%m-%d_%H-%M-%S}':x=24:y=24:fontsize=24:fontcolor=white:box=1:boxcolor=black@0.70:boxborderw=12" \
  -force_key_frames "expr:gte(t,n_forced*2)" \
  -c:v libx264 -preset veryfast -b:v 2500k -r 25 -g 50 -keyint_min 50 -sc_threshold 0 \
  -c:a aac -b:a 128k \
  -f hls -hls_time 2 -hls_list_size 8 -hls_delete_threshold 2 \
  -hls_segment_type fmp4 -hls_fmp4_init_filename init.mp4 \
  -strftime 1 \
  -start_number "$START_NUM" \
  -hls_flags independent_segments+temp_file+delete_segments+program_date_time+omit_endlist \
  -hls_segment_filename "/out/seg-%Y%m%dT%H%M%SZ.m4s" \
  /out/live.m3u8 &
FFMPEG_PID=$!

# Wait for whichever process exits first, then tear the other one down too.
wait -n "$NGINX_PID" "$FFMPEG_PID"
EXIT_CODE=$?

kill "$NGINX_PID" "$FFMPEG_PID" 2>/dev/null || true
wait "$NGINX_PID" "$FFMPEG_PID" 2>/dev/null || true

exit "$EXIT_CODE"
