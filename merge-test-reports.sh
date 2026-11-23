#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
root=$PWD

if ! command -v checkbox-cli >/dev/null; then
    echo "Error: checkbox-cli not found." >&2
    exit 1
fi

directories=("$root"/*/)
if ((${#directories[@]} == 0)); then
    echo "Error: no device directories found in $root." >&2
    exit 1
fi

archives=()
for directory in "${directories[@]}"; do
    directory=${directory%/}
    name=${directory##*/}
    inputs=("$directory"/*/*.xz)
    if ((${#inputs[@]} == 0)); then
        echo "Error: no */*.xz input files found in $directory." >&2
        exit 1
    fi
    archives+=("$directory/$name.tar.xz")
done

read_segment() {
    printf '%s: ' "$1" >&2
    if ! IFS= read -r REPLY; then
        echo "Error: input ended before all report details were provided." >&2
        exit 1
    fi
    if [[ ! $REPLY =~ [^[:space:]] || $REPLY == */* ]]; then
        echo "Error: each report detail must be non-empty and cannot contain '/'." >&2
        exit 1
    fi
}

read_segment 'Model name'
model=$REPLY
read_segment 'Code name'
code=$REPLY
read_segment 'Milestone'
milestone=$REPLY
channel_file=/var/lib/ubuntu_dist_channel
if [[ -r "$channel_file" ]] &&
    descriptor=$(awk '
        /^[[:space:]]*(#|$)/ { next }
        { gsub(/^[[:space:]]+|[[:space:]]+$/, ""); value = $0; count++ }
        END { if (count != 1) exit 1; print value }
    ' "$channel_file") &&
    [[ $descriptor =~ ^[[:alnum:]._-]+-[[:alnum:]._]+-[[:alnum:]._]+$ ]]; then
    last=${descriptor##*-}
    rest=${descriptor%-*}
    version="${rest##*-}-$last"
    printf 'Image version: %s\n' "$version"
else
    printf 'Warning: cannot read a valid image version from %s; enter it manually.\n' "$channel_file" >&2
    read_segment 'Image version'
    version=$REPLY
fi
report="${model}_${code}_${milestone}_${version}_test-report.html"

outputs=("${archives[@]}" "$root/$report")
existing=()
for output in "${outputs[@]}"; do
    if [[ -e "$output" || -L "$output" ]]; then
        existing+=("$output")
    fi
done
if ((${#existing[@]})); then
    printf 'The following output files already exist and will be overwritten:\n' >&2
    printf '  %s\n' "${existing[@]}" >&2
    printf 'Continue? [y/N] ' >&2
    if ! IFS= read -r answer || [[ ! $answer =~ ^[Yy]$ ]]; then
        echo "Cancelled." >&2
        exit 1
    fi
fi

total=$((${#directories[@]} + 1))
for ((i = 0; i < ${#directories[@]}; i++)); do
    directory=${directories[i]%/}
    name=${directory##*/}
    inputs=("$directory"/*/*.xz)
    printf '[%d/%d] Merging %s test results...\n' "$((i + 1))" "$total" "$name"
    checkbox-cli merge-submissions "${inputs[@]}" -o "${archives[i]}" --title "$name"
done
printf '[%d/%d] Generating merged report...\n' "$total" "$total"
checkbox-cli merge-reports "${archives[@]}" -o "$root/$report"
printf 'Report generated: %s/%s\n' "$root" "$report"
