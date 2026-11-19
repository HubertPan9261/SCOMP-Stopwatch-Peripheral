#!/bin/sh
set -eu
verification_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
project_dir="$verification_dir/../SCOMP_Stopwatch"
if ! command -v ghdl >/dev/null 2>&1; then
    echo "GHDL is required. On Ubuntu: sudo apt install ghdl" >&2
    exit 127
fi
build_dir=$(mktemp -d)
trap 'rm -rf "$build_dir"' EXIT HUP INT TERM
cd "$build_dir"
ghdl -a --std=08 "$project_dir/SW_CORE.vhd" "$project_dir/SW_IO.vhd" "$verification_dir/tb_stopwatch.vhd"
ghdl -e --std=08 tb_stopwatch
ghdl -r --std=08 tb_stopwatch --assert-level=error
