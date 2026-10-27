#!/usr/bin/env bash
shopt -s nullglob nocaseglob
export LC_ALL=C

output="fonts.hpp"

error() {
    echo "$@" >&2
    exit 1
}

cleanup() {
    local status=$?
    (( status != 0 )) && rm -f "$output"
    read -rp "Press enter to continue..."
    exit $status
}
trap 'cleanup' EXIT

export PATH="$PATH:$PWD"
if ! which binary_to_compressed_c &> /dev/null; then
    error "the program \"binary_to_compressed_c\" was not found in current location or in \$PATH"
fi

rm -f "$output"

count=0
for f in *.ttf *.otf; do
    # Set "symbol" to file name without extension
    symbol="${f%.*}"
    # Replace all dashes and spaces with underscores
    symbol="${symbol//[- ]/_}"
    if [[ ! "$symbol" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        error "Error parsing \"$f\": names can only contains characters from A-Z, 0-9, underscores dashes and spaces and cannot start with a digit"
    else
        if ! binary_to_compressed_c "$f" "$symbol" >> "$output"; then
            error "Command \"binary_to_compressed_c \"$f\" $symbol\" failed"
        fi
        echo "\"$f\" done"
        echo Symbols:
        echo "    ${symbol}_compressed_size"
        echo "    ${symbol}_compressed_data"
        ((count++))
    fi
done

if (( count == 0 )); then
    error "No .ttf or .otf font files found!"
else
    sed -i 's/static const/inline constexpr/g' "$output"
    echo "Done $count font/s."
fi
