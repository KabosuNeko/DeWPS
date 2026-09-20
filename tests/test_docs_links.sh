#!/usr/bin/env bash
# Verify that relative Markdown links in repository docs point to existing
# files. Anchors are not validated (GitHub slug rules are outside scope).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fails=0
checked=0
while IFS= read -r file; do
    while IFS= read -r link; do
        target=${link%%#*}
        target=${target%%\?*}
        [[ -z "$target" ]] && continue
        [[ "$target" == http://* || "$target" == https://* || "$target" == mailto:* ]] && continue
        checked=$((checked + 1))
        if [[ ! -e "$(dirname "$file")/$target" ]]; then
            echo "BROKEN: $file -> $link"
            fails=$((fails + 1))
        fi
    done < <(grep -oE '\]\([^)]+\)' "$file" | sed 's/^](//; s/)$//' || true)
done < <(find . -name '*.md' -not -path './.git/*' | sort)

echo "Checked $checked relative link(s) in Markdown files"
echo "RESULT: $fails broken link(s)"
exit "$fails"
