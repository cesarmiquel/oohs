#!/bin/bash
# Run a .com in headless DOSBox and log everything it sends to the MIDI port.
#
# DOSBox's MPU-401 output goes to an aseqdump ALSA client instead of a synth,
# and every event is printed with the seconds elapsed since the capture started.
#
# Usage: ./midi_capture.sh [SECONDS] [FILE.com] [CYCLES]
#   SECONDS   how long to run (default 60)
#   FILE.com  program to run (default: build src/fp26.asm with -DMUSIC)
#   CYCLES    DOSBox cycles setting (default 50000, try "max")
#
# Needs: dosbox, aseqdump/aconnect (alsa-utils), nasm.

set -e

secs=${1:-60}
com=$2
cycles=${3:-50000}
here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
trap 'kill $dump_pid 2>/dev/null; rm -rf "$tmp"' EXIT

mkdir "$tmp/dos"
if [ -z "$com" ]; then
  nasm "$here/src/fp26.asm" -fbin -O0 -DMUSIC -o "$tmp/dos/FP.COM"
else
  cp "$com" "$tmp/dos/FP.COM"
fi

# Start aseqdump, prefixing each line with the elapsed time.
start=$(date +%s%N)
aseqdump > >(while IFS= read -r line; do
  now=$(date +%s%N)
  printf '%8.3f  %s\n' "$(( (now - start) / 1000000 ))e-3" "$line"
done) 2>&1 &
dump_pid=$!
sleep 1

# Find aseqdump's ALSA client number by its pid.
port=$(aconnect -l | grep "pid=$dump_pid" | sed -E 's/client ([0-9]+):.*/\1/')
if [ -z "$port" ]; then
  echo "could not find the aseqdump ALSA client" >&2
  exit 1
fi

cat > "$tmp/dosbox.conf" <<EOF
[sdl]
output=surface
[cpu]
core=dynamic
cputype=pentium_slow
cycles=$cycles
[midi]
mpu401=uart
mididevice=alsa
midiconfig=$port:0
[mixer]
nosound=true
[autoexec]
mount c $tmp/dos
c:
FP.COM
EOF

echo "running for ${secs}s (cycles=$cycles), MIDI -> aseqdump $port:0" >&2
SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy \
  timeout "$secs" dosbox -conf "$tmp/dosbox.conf" -noconsole > /dev/null 2>&1 || true

kill $dump_pid 2>/dev/null || true
sleep 0.2
