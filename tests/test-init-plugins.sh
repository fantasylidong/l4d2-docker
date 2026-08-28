#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$repo_root/entrypoints/init-plugins.sh"

for value in true TRUE True 1 yes YES on ON; do
	mysqlexist="$value"
	mysql_exists || { echo "Expected mysqlexist=$value to enable database mode"; exit 1; }
done

for value in false 0 no off ''; do
	mysqlexist="$value"
	if mysql_exists; then
		echo "Expected mysqlexist=$value to use no-database mode"
		exit 1
	fi
done

unset mysqlexist
if mysql_exists; then
	echo "Expected an unset mysqlexist to use no-database mode"
	exit 1
fi

cloud=true
PORT=27001
mysqlexist=false
[[ "$(autoupdate_mode)" == "1" ]] || { echo "Expected no-database updater mode 1"; exit 1; }
mysqlexist=true
[[ "$(autoupdate_mode)" == "2" ]] || { echo "Expected database updater mode 2"; exit 1; }
cloud=false
PORT=2330
mysqlexist=false
[[ "$(autoupdate_mode)" == "1" ]] || { echo "Expected local no-database updater mode 1"; exit 1; }
mysqlexist=true
[[ "$(autoupdate_mode)" == "2" ]] || { echo "Expected local database updater mode 2"; exit 1; }

echo "init-plugins.sh mysqlexist tests passed"
