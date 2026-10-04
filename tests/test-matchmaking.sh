#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/cfg"
script="$root/entrypoints/configure-matchmaking.sh"
template() {
  printf '%s\n' 'sv_search_key "legacy-key"' 'sv_steamgroup "111,222"' \
    'sv_hosting_lobby 1' 'sv_steamgroup_exclusive 1' >"$work/cfg/server.cfg"
}
check_effective() {
  python3 - "$work/cfg" "$1" <<'PY'
import pathlib,shlex,sys
root=pathlib.Path(sys.argv[1]);values={}
def execute(name):
    for line in (root/name).read_text().splitlines():
        args=shlex.split(line.split('//',1)[0])
        if not args:continue
        if args[0]=='exec':execute(args[1])
        elif len(args)==2:values[args[0]]=args[1]
execute('server.cfg')
assert values['sv_search_key']==sys.argv[2],values
assert values['sv_steamgroup']=='111,222',values
assert values['sv_hosting_lobby']=='1',values
if not sys.argv[2]:assert values['sv_steamgroup_exclusive']=='0',values
PY
}

# An unset option preserves legacy configuration, even before plugin setup.
env -u SRCDS_PUBLIC_MATCHMAKING bash "$script" "$work/missing"
template
cp "$work/cfg/server.cfg" "$work/original"
SRCDS_PUBLIC_MATCHMAKING=false bash "$script" "$work/cfg"
cmp "$work/original" "$work/cfg/server.cfg"
printf 'user-owned config\n' >"$work/cfg/anne-public-matchmaking.cfg"
SRCDS_PUBLIC_MATCHMAKING=false bash "$script" "$work/cfg"
grep -qx 'user-owned config' "$work/cfg/anne-public-matchmaking.cfg"
if SRCDS_PUBLIC_MATCHMAKING=true bash "$script" "$work/cfg" >/dev/null 2>&1; then exit 1; fi
rm "$work/cfg/anne-public-matchmaking.cfg"

# Recreating a container restores the template first. Each boot must recreate
# the override; executing server.cfg again models the next map's configuration.
for generation in 1 2; do
  template
  SRCDS_PUBLIC_MATCHMAKING=true bash "$script" "$work/cfg"
  SRCDS_PUBLIC_MATCHMAKING=true bash "$script" "$work/cfg"
  [[ "$(grep -c '^exec anne-public-matchmaking.cfg' "$work/cfg/server.cfg")" == 1 ]]
  check_effective ''
  check_effective ''
done
SRCDS_PUBLIC_MATCHMAKING=false bash "$script" "$work/cfg"
check_effective legacy-key
for value in On Yes tRuE TRUE 1; do
  SRCDS_PUBLIC_MATCHMAKING="$value" bash "$script" "$work/cfg"
  check_effective ''
done
for value in Off No fAlSe FALSE 0 ''; do
  SRCDS_PUBLIC_MATCHMAKING="$value" bash "$script" "$work/cfg"
  check_effective legacy-key
done
for bad in invalid; do
  if SRCDS_PUBLIC_MATCHMAKING="$bad" bash "$script" "$work/cfg" >/dev/null 2>&1; then exit 1; fi
done
if SRCDS_PUBLIC_MATCHMAKING=true private=false bash "$script" "$work/cfg" >/dev/null 2>&1; then exit 1; fi
if SRCDS_PUBLIC_MATCHMAKING=true lobby=true bash "$script" "$work/cfg" >/dev/null 2>&1; then exit 1; fi
if SRCDS_PUBLIC_MATCHMAKING=true bash "$script" "$work/missing" >/dev/null 2>&1; then exit 1; fi

# Exercise the real post-initialization ordering and failure propagation without
# starting the image's unrelated link watcher or a game server.
mkdir -p "$work/startup/enthooks"
sed -n '/^bash .\/refresh-addons.sh/,$p' "$root/entrypoints/entrypoint.sh" >"$work/startup/start.sh"
printf 'exit 0\n' >"$work/startup/refresh-addons.sh"
printf 'printf '\''sv_search_key "legacy-key"\\nsv_steamgroup "111,222"\\nsv_hosting_lobby 1\\n'\'' >"$TEST_CFG_DIR/server.cfg"\n' >"$work/startup/init-plugins.sh"
printf 'echo '\''sv_search_key "post-init-key"'\'' >>"$TEST_CFG_DIR/server.cfg"\n' >"$work/startup/enthooks/post-init.sh"
printf 'bash "$TEST_MATCH_SCRIPT" "$TEST_CFG_DIR"\n' >"$work/startup/configure-matchmaking.sh"
printf 'touch "$TEST_RUN_MARKER"\n' >"$work/startup/run.sh"
export TEST_CFG_DIR="$work/cfg" TEST_MATCH_SCRIPT="$script" TEST_RUN_MARKER="$work/ran"
(cd "$work/startup" && SRCDS_PUBLIC_MATCHMAKING=true bash ./start.sh >/dev/null)
test -f "$work/ran"
check_effective ''
rm "$work/ran"
if (cd "$work/startup" && SRCDS_PUBLIC_MATCHMAKING=true private=false bash ./start.sh >/dev/null 2>&1); then exit 1; fi
test ! -f "$work/ran"
echo 'public matchmaking startup tests passed'
