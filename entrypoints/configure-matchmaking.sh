#!/usr/bin/env bash
set -euo pipefail

# Applied after plugin initialization on every container start.
mode="$(printf '%s' "${SRCDS_PUBLIC_MATCHMAKING:-false}" | tr '[:upper:]' '[:lower:]')"
case "$mode" in
  true|1|yes|on) enabled=true ;;
  false|0|no|off|'') enabled=false ;;
  *) echo "Invalid SRCDS_PUBLIC_MATCHMAKING boolean" >&2; exit 1 ;;
esac

cfg_dir="${1:-/home/louis/l4d2/left4dead2/cfg}"
runtime_cfg="$cfg_dir/anne-public-matchmaking.cfg"
server_cfg="$cfg_dir/server.cfg"
marker='// Managed by Anne public matchmaking. Do not edit.'
temporary=''
server_temporary=''
trap 'rm -f -- "$temporary" "$server_temporary"' EXIT

if [[ "$enabled" == false ]]; then
  # An unset flag preserves legacy startup. Disabling a previous override lets
  # server.cfg and the engine's normal map configuration take effect again.
  if [[ -f "$runtime_cfg" ]] && [[ "$(head -n 1 "$runtime_cfg")" == "$marker" ]]; then
    temporary="$(mktemp "$cfg_dir/.anne-public-matchmaking.XXXXXX")"
    printf '%s\n' "$marker" '// Public matchmaking override disabled.' >"$temporary"
    chmod 0644 "$temporary"
    mv -- "$temporary" "$runtime_cfg"
  fi
  exit 0
fi

if [[ -f "$runtime_cfg" ]] && [[ "$(head -n 1 "$runtime_cfg")" != "$marker" ]]; then
  echo "Refusing to replace unmanaged anne-public-matchmaking.cfg" >&2
  exit 1
fi

# Legacy flags rewrite lobby state during init-plugins and conflict with the
# reservation manager. Even private=false is treated as enabled by old images.
if [[ -n "${private:-}" || "${lobby:-}" == true ]]; then
  echo "Public matchmaking requires legacy private and lobby=true to be unset" >&2
  exit 1
fi
if [[ ! -f "$server_cfg" ]]; then
  echo "Public matchmaking requires an initialized server.cfg" >&2
  exit 1
fi

temporary="$(mktemp "$cfg_dir/.anne-public-matchmaking.XXXXXX")"
{
  printf '%s\n' "$marker"
  printf '%s\n' 'sv_search_key ""' 'sv_steamgroup_exclusive 0' \
    'sv_allow_lobby_connect_only 0' 'sv_lan 0'
  printf '%s\n' '// Reservation cookie and sv_hosting_lobby remain plugin-managed.'
} >"$temporary"
chmod 0644 "$temporary"

server_temporary="$(mktemp "$cfg_dir/.server.cfg.XXXXXX")"
cp -p -- "$server_cfg" "$server_temporary"
awk '
  /^[[:space:]]*exec[[:space:]]+"?anne-public-matchmaking[.]cfg"?[[:space:]]*(\/\/.*)?$/ { next }
  { print }
  END { print "exec anne-public-matchmaking.cfg // managed-public-matchmaking" }
' "$server_cfg" >"$server_temporary"
# Install the target before the exec line; readers always find a complete file.
mv -- "$temporary" "$runtime_cfg"
mv -- "$server_temporary" "$server_cfg"
