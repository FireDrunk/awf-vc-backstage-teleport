#!/bin/bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
key_path="$script_dir/deploy"
pub_key_path="$key_path.pub"

if [[ -e "$key_path" || -e "$pub_key_path" ]]; then
  echo "SSH key files already exist, skipping generation."
  exit 0
fi

ssh-keygen -q -f "$key_path" -N ""
echo "SSH key files generated."
