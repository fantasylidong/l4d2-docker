#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/l4d2"

cat >"$tmpdir/l4d2/srcds_run" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$@" >"$SRCDS_ARGS_FILE"
STUB
chmod +x "$tmpdir/l4d2/srcds_run"

run_srcds() {
  local case_name="$1"
  shift

  local args_file="$tmpdir/${case_name}.args"
  (
    cd "$tmpdir"
    env -i PATH="$PATH" PORT=27015 MAP=c1m1_hotel SRCDS_ARGS_FILE="$args_file" "$@" \
      bash "$repo_root/entrypoints/run.sh"
  )
  printf '%s\n' "$args_file"
}

assert_has_arg() {
  local arg="$1"
  local args_file="$2"

  if ! grep -Fx -- "$arg" "$args_file" >/dev/null; then
    echo "Expected $arg in $(basename "$args_file")"
    echo "Actual args:"
    cat "$args_file"
    exit 1
  fi
}

assert_no_arg() {
  local arg="$1"
  local args_file="$2"

  if grep -Fx -- "$arg" "$args_file" >/dev/null; then
    echo "Did not expect $arg in $(basename "$args_file")"
    echo "Actual args:"
    cat "$args_file"
    exit 1
  fi
}

args_file="$(run_srcds no_nomaster)"
assert_no_arg "-nomaster" "$args_file"

args_file="$(run_srcds nomaster_enabled nomaster=true)"
assert_has_arg "-nomaster" "$args_file"

args_file="$(run_srcds nomaster_with_ip nomaster=true IP=127.0.0.1)"
assert_has_arg "-nomaster" "$args_file"
assert_has_arg "127.0.0.1" "$args_file"

echo "run.sh nomaster tests passed"
