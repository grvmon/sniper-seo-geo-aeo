#!/usr/bin/env bash
# Fixture tests for scripts/verify-page.sh. Usage: bash tests/run.sh
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VP="$DIR/scripts/verify-page.sh"
PASS=0; FAIL=0
ok() { PASS=$((PASS+1)); echo "ok   $1"; }
bad() { FAIL=$((FAIL+1)); echo "FAIL $1"; [[ -n "${2:-}" ]] && echo "$2" | sed 's/^/     /'; }

# scenario MODE PATH NAME REGEX...  (every regex must match a line of output)
scenario() {
  local mode="$1" path="$2" name="$3"; shift 3
  local pf; pf="$(mktemp)"; rm -f "$pf"
  python3 "$DIR/tests/fixture_server.py" "$mode" "$pf" & local pid=$!
  for _ in $(seq 50); do [[ -s "$pf" ]] && break; sleep 0.1; done
  local out; out="$(bash "$VP" "http://127.0.0.1:$(cat "$pf")$path" 2>&1)"; local rc=$?
  kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null; rm -f "$pf"
  [[ $rc -eq 0 ]] || { bad "$name (exit $rc)" "$out"; return; }
  for re in "$@"; do
    grep -Eq -- "$re" <<<"$out" || { bad "$name: missing /$re/" "$out"; return; }
  done
  ok "$name"
}

scenario blankline /page "robots blank line inside group" $'^robots_agent: GPTBot\ttraining\tgroup=GPTBot\tdisallow'
scenario multiua /page "robots multiple UAs then blank lines" $'^robots_agent: CCBot\ttraining\tgroup=CCBot\tdisallow' $'^robots_agent: Googlebot\tsearch\tgroup=\\*\tallow'
scenario tie /page "robots allow/disallow tie -> allow" $'^robots_agent: Googlebot\tsearch\tgroup=\\*\tallow'
scenario bom /page "robots BOM stripped" $'^robots_agent: Googlebot\tsearch\tgroup=\\*\tdisallow'
scenario norobots /page "no robots.txt -> allow all" '^robots_txt_status: 404' $'^robots_agent: GPTBot\ttraining\tgroup=none\tallow' '^in_sitemap: nt'
scenario twosm /page "two sitemaps, page in second" '^sitemap_files_read: 2' '^in_sitemap: yes'
scenario gz /page "gz sitemap" '^in_sitemap: yes'
scenario index /page "sitemap index expanded" '^sitemap_files_read: 2' '^in_sitemap: yes'
scenario loop /page "sitemap index loop terminates" '^sitemap_files_read: 2' '^in_sitemap: no'
scenario x /hop "redirect-hop noindex ignored" '^hop_status: 301 200' '^x_robots_tag: \(none\)' '^indexability: pass'
scenario x /gb "googlebot meta noindex" '^indexability: fail'
scenario x /xrt-other "other-bot XRT reported, not judged" '^x_robots_other_agent: otherbot' '^indexability: pass'
scenario x /xrt-google "googlebot-scoped XRT judged" '^indexability: fail'
scenario x /404 "404 page fails" '^http_check: fail' '^indexability: fail'
scenario x /403 "403 is nt, not fail" '^http_check: fail' '^indexability: nt' '^index_note: status 403'
scenario x /dupcanon "identical canonicals count once" '^canonical_unique_count: 1' '^canonical_differs: none'
scenario x /shell "JS shell flagged" '^js_shell_suspect: yes'
scenario x /page "normal page not a shell" '^js_shell_suspect: no'
scenario x "/canq?b=2" "canonical differs by query" '^canonical_matches_final: no' '^canonical_differs: query'
scenario x "/canq?a=1" "canonical with same query matches" '^canonical_matches_final: yes' '^canonical_differs: none'

# usage errors
for args in "" "file:///etc/passwd" "a b"; do
  # shellcheck disable=SC2086
  bash "$VP" $args >/dev/null 2>&1; rc=$?
  [[ $rc -eq 2 ]] && ok "exit 2 for args '$args'" || bad "exit $rc (want 2) for args '$args'"
done

# Python compatibility: compile the embedded program on every python3.x found
PY_SRC="$(mktemp)"; sed -n "/<< 'PY'/,/^PY$/p" "$VP" | sed '1d;$d' > "$PY_SRC"
found=0
for py in $(compgen -c python3. | grep -E '^python3\.[0-9]+$' | sort -u) python3; do
  command -v "$py" >/dev/null || continue
  found=1
  "$py" -c "import sys; compile(open(sys.argv[1]).read(), 'verify', 'exec')" "$PY_SRC" 2>/dev/null \
    && ok "compiles on $($py -V 2>&1)" || bad "SyntaxError on $($py -V 2>&1)"
done
[[ $found -eq 1 ]] || bad "no python3 found"
rm -f "$PY_SRC"

echo "passed: $PASS failed: $FAIL"
[[ $FAIL -eq 0 ]]
