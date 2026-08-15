#!/bin/bash
set -euo pipefail

patch_root="$HOME/.pi/patches"
package_root="$HOME/.pi/agent/npm/node_modules"

if [[ ! -d "$patch_root" ]]; then
  exit 0
fi

while IFS= read -r patch_file; do
  relative_file="${patch_file#"$patch_root/"}"
  target="${relative_file%%/*}"
  target="${target}/${relative_file#*/}"
  target="${target%/*}"
  package_dir="$package_root/$target"

  if [[ ! -d "$package_dir" ]]; then
    echo "Patch target is missing for $relative_file: $package_dir" >&2
    exit 1
  fi

  if (cd "$package_dir" && patch --dry-run -f -p0 < "$patch_file" >/dev/null 2>&1); then
    echo "Applying $relative_file"
    (cd "$package_dir" && patch -f -p0 < "$patch_file" >/dev/null)
    continue
  fi

  if (cd "$package_dir" && patch --dry-run -f -R -p0 < "$patch_file" >/dev/null 2>&1); then
    continue
  fi

  echo "Patch does not match the installed package: $relative_file" >&2
  exit 1
done < <(find -L "$patch_root" -type f -name '*.patch' -print | sort)
