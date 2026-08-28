#!/usr/bin/env bash
#
# build-index.sh [registry-root] — regenerate index.json from plugins/*.json.
#
# THE ENTRIES ARE THE SOURCE OF TRUTH AND THIS FILE IS DERIVED. One file per plugin, named by the plugin's
# own id, is what makes two submissions on the same day two pull requests with no line in common — and it is
# what makes id-uniqueness a property of git rather than of a check somebody has to remember to run.
#
# Deliberately jq and not Java: index.json is a concatenation, not a decision. The decision — does this
# plugin load, does it collide with one already here — is `botmaker validate`'s, run by .github/workflows/
# validate.yml through the same library the plugin's author ran locally.
#
# `sort` because the shell's glob order is locale-dependent, and a regenerated index that reorders itself
# produces a diff nobody can read. Filenames are ids, so sorting files sorts entries by id.
set -euo pipefail

root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$root"

entries=()
while IFS= read -r file; do
    entries+=("$file")
done < <(find plugins -maxdepth 1 -name '*.json' | sort)

if [ ${#entries[@]} -eq 0 ]; then
    # An empty registry is a real state — it is the state this repository ships in — and it must produce
    # valid JSON, because Studio's Manage Plugins parses this file before it has any reason to believe
    # anything is in it.
    printf '[]\n' > index.json
else
    jq -s '.' "${entries[@]}" > index.json
fi

printf 'index.json: %d entr%s\n' "${#entries[@]}" "$([ ${#entries[@]} -eq 1 ] && echo y || echo ies)" >&2
