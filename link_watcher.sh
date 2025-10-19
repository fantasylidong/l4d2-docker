#!/usr/bin/env bash
set -euo pipefail

SRC="${1:-/map}"
DST="${2:-/home/louis/l4d2/left4dead2/addons}"

# 规范：去掉尾斜杠，避免路径裁剪失败
SRC="${SRC%/}"
DST="${DST%/}"

mkdir -p "$DST"

command -v inotifywait >/dev/null 2>&1 || {
  echo "[link_watcher] inotifywait not found. Install inotify-tools first." >&2
  exit 1
}

link_one() {
  local path="$1"
  # 只处理文件；目录直接跳过
  [ -f "$path" ] || return 0

  # 保留子目录结构
  local rel="${path#"$SRC"/}"
  local destdir="$DST/$(dirname "$rel")"
  mkdir -p "$destdir"

  local base
  base="$(basename "$path")"
  local link="$destdir/$base"

  # 覆盖模式
  ln -sf "$path" "$link" && echo "[link_watcher] Linked (overwrite): $path -> $link"
}

# 冷启动：把已有文件先全部链接一次
find "$SRC" -type f -print0 | while IFS= read -r -d '' f; do
  link_one "$f"
done

# 监听：仅在写完或移入时触发，避免半成品
inotifywait -m -r -e close_write,moved_to --format '%w%f' --quiet "$SRC" \
| while IFS= read -r path; do
    link_one "$path"
  done
