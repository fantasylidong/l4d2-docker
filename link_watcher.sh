#!/usr/bin/env bash
set -euo pipefail

SRC="${1:-/map}"
DST="${2:-/home/louis/l4d2/left4dead2/addons}"

mkdir -p "$DST"

# 若 inotify-tools 不在，提前提示
command -v inotifywait >/dev/null 2>&1 || {
  echo "[link_watcher] inotifywait not found. Install inotify-tools first." >&2
  exit 1
}

# 递归监听：新建子目录也会被跟踪
# 只在文件写完(close_write)或被移入(moved_to)时触发
inotifywait -m -r -e close_write,create,moved_to --format '%w%f' --quiet "$SRC" \
| while IFS= read -r path; do
  # 忽略目录
  [ -d "$path" ] && continue

  # 保留子目录结构
  rel="${path#$SRC/}"
  destdir="$DST/$(dirname "$rel")"
  mkdir -p "$destdir"

  base="$(basename "$path")"
  link="$destdir/$base"

  # 覆盖模式 (-sf)
  ln -sf "$path" "$link" && echo "[link_watcher] Linked (overwrite): $path -> $link"
done

