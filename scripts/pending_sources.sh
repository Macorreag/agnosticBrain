#!/usr/bin/env bash
set -euo pipefail

log_file="wiki/log.md"
skip_file="wiki/.skip-sources.md"

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/agnosticbrain-pending.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

all_sources="$tmp_dir/all.txt"
done_sources="$tmp_dir/done.txt"
skip_sources="$tmp_dir/skip.txt"

find raw -type f -name '*.md' -print | LC_ALL=C sort > "$all_sources"

if [[ -f "$log_file" ]]; then
  grep -h '^Fuentes:' "$log_file" \
    | perl -nE 'while (/`(raw\/[^`]+?\.md)`/g) { say $1 }' \
    | LC_ALL=C sort -u > "$done_sources"
else
  : > "$done_sources"
fi

if [[ -f "$skip_file" ]]; then
  perl -nE 'say $1 if /^\s*(raw\/.*?\.md)(?:\s+(?:-|—).*)?$/' "$skip_file" \
    | LC_ALL=C sort -u > "$skip_sources"
else
  : > "$skip_sources"
fi

comm -23 "$all_sources" "$done_sources" | comm -23 - "$skip_sources" \
  | awk '
    function rank(path) {
      if (path ~ /^raw\/Daily Notes\//) return 10
      return 90
    }
    { printf "%03d\t%s\n", rank($0), $0 }
  ' \
  | LC_ALL=C sort -k1,1n -k2,2 \
  | cut -f2-
