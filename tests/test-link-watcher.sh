#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'chmod 700 "$tmpdir/src/.upload-records"; rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/bin" "$tmpdir/src/.upload-records" "$tmpdir/dst"
touch "$tmpdir/src/existing map.vpk" "$tmpdir/src/.pending.part"
touch "$tmpdir/src/.upload-records/private.json"
chmod 000 "$tmpdir/src/.upload-records"

cat >"$tmpdir/bin/inotifywait" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
[[ " $* " == *" --exclude (^|/)\. "* ]]
test -L "$WATCHER_TEST_DST/existing map.vpk"
test ! -e "$WATCHER_TEST_DST/.upload-records"
test ! -e "$WATCHER_TEST_DST/.pending.part"

wait_for_link() {
  local present="$1" i
  for i in {1..100}; do
    if [ -L "$WATCHER_TEST_DST/new map.vpk" ]; then
      [ "$present" = yes ] && return 0
    else
      [ "$present" = no ] && return 0
    fi
    sleep 0.05
  done
  return 1
}

touch "$WATCHER_TEST_SRC/new map.vpk"
printf 'MOVED_TO|%s/new map.vpk\n' "$WATCHER_TEST_SRC"
wait_for_link yes
rm "$WATCHER_TEST_SRC/new map.vpk"
printf 'DELETE|%s/new map.vpk\n' "$WATCHER_TEST_SRC"
wait_for_link no
STUB
chmod +x "$tmpdir/bin/inotifywait"

PATH="$tmpdir/bin:$PATH" WATCHER_TEST_SRC="$tmpdir/src" WATCHER_TEST_DST="$tmpdir/dst" \
  bash "$repo_root/link_watcher.sh" "$tmpdir/src" "$tmpdir/dst"
echo "link_watcher.sh private-directory and upload event tests passed"
