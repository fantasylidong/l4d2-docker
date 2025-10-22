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

  local rel="${path#"$SRC"/}"
  local dest="$DST/$rel"
  mkdir -p "$(dirname "$dest")"

  ln -sf "$path" "$dest" \
    && echo "[link_watcher] Linked (overwrite): $path -> $dest"
}

unlink_one() {
  local src_path="$1"
  # 事件里传来的是 SRC 内的绝对路径（目录已不存在也没关系）
  # 我们按同结构映射到 DST 并删除符号链接
  local rel="${src_path#"$SRC"/}"
  local dest="$DST/$rel"

  if [ -L "$dest" ]; then
    rm -f -- "$dest"
    echo "[link_watcher] Unlinked symlink: $dest"
    prune_empty_dirs "$(dirname "$dest")"
  fi
}

# 清理空目录（不向上越过 DST 根）
prune_empty_dirs() {
  local d="$1"
  while [ "$d" != "$DST" ] && [ "$d" != "/" ]; do
    # 若目录为空则删除，直到遇到非空或到达 DST 根
    if [ -d "$d" ] && [ -z "$(ls -A "$d")" ]; then
      rmdir --ignore-fail-on-non-empty "$d" || break
      d="$(dirname "$d")"
    else
      break
    fi
  done
}

# 冷启动：把已有文件先全部链接一次
find "$SRC" -type f -print0 | while IFS= read -r -d '' f; do
  link_one "$f"
done

# 监听：新增/写完/移入 + 删除/移出
# 说明：
# - CLOSE_WRITE|CREATE|MOVED_TO 触发链接/覆盖
# - DELETE|MOVED_FROM 触发在 DST 侧删除对应符号链接
inotifywait -m -r \
  -e close_write,create,moved_to,delete,moved_from \
  --format '%e|%w%f' --quiet "$SRC" |
while IFS='|' read -r ev path; do
  # 跳过目录事件（ISDIR）
  case "$ev" in
    *ISDIR*) continue ;;
  esac

  case "$ev" in
    *CLOSE_WRITE*|*CREATE*|*MOVED_TO*)
      # 仅当源端此刻是个“文件”时才建立链接
      [ -f "$path" ] && link_one "$path"
      ;;
    *DELETE*|*MOVED_FROM*)
      # 源文件删除/移出，删除 DST 对应符号链接
      unlink_one "$path"
      ;;
  esac
done
