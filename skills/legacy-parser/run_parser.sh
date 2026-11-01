#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 1 ]; then
        echo "Usage: $0 /home/pradeep/csce465-agentsec/465_HW3/inbox/<filename>" >&2
	exit 1
fi

full_dir="/home/pradeep/csce465-agentsec/465_HW3/inbox"
param="$1"

case "$param" in
	"$full_dir"/*) ;;
	*) echo "Error: File must be under $full_dir" >&2; exit 1 ;;
esac

if [ ! -f "$param" ]; then
	echo "Error: Invalid file" >&2
	exit 1
fi

exec /home/pradeep/csce465-agentsec/465_HW3/src/legacy_log_parser "$param"
