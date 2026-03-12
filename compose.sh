#!/bin/bash

# Usage: compose.sh <template_dir> <fragment1.md> [fragment2.md] ...
# Concatenates markdown fragments into <template_dir>/CLAUDE.md
# All fragments are passed as arguments — no hardcoded base.

template_dir=$1
shift

output_file="$template_dir/CLAUDE.md"
temp_file=$(mktemp)

for md_file in "$@"; do
    tr -d '\000-\010\013\014\016-\037\177' < "$md_file" >> "$temp_file"
    echo "" >> "$temp_file"
    echo "" >> "$temp_file"
done

mv "$temp_file" "$output_file"

echo "Created $output_file from:"
for md_file in "$@"; do
    echo "  - $md_file"
done
