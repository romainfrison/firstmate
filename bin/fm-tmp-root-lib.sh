#!/usr/bin/env bash
# Single owner of Firstmate's machine-wide temporary root, /tmp/firstmate
# (/private/tmp/firstmate on macOS), under which every per-task temp root, every
# staged launch directory, and the Herdr presentation lock namespace live.
#
# One fixed parent instead of one /tmp/fm-<id> sibling per task lets an
# operator who runs Firstmate under an OS sandbox grant writes on exactly one
# named directory, the way ~/.no-mistakes/repos is granted, rather than either
# opening all of /tmp or leaving every spawn and teardown outside the sandbox.
# The path is predictable under a shared /tmp, so the root is accepted only as
# a real directory (never a symlink) owned by this user and writable by nobody
# else, and it is created mode 0700; children keep their own private checks.
#
# Usage: . bin/fm-tmp-root-lib.sh   (no FM_* setup required, no side effects)
#   fm_tmp_root                   print the root path
#   fm_tmp_root_ensure            create or validate the root; non-zero with a
#                                 message on stderr when it is unsafe
#   fm_task_tmp_dir <id>          print a task's temp root under it
#   fm_task_launch_dir <id> <tok> print a task's per-home launch directory

fm_tmp_root() {
  printf '%s' /tmp/firstmate
}

fm_tmp_root_ensure() {
  local root
  root=$(fm_tmp_root)
  if (umask 077 && mkdir "$root") 2>/dev/null; then
    return 0
  fi
  if [ -L "$root" ] || [ ! -d "$root" ] || [ ! -O "$root" ] ||
    [ -n "$(find "$root" -prune \( -perm -g=w -o -perm -o=w \) -print 2>/dev/null)" ] ||
    ! chmod 700 "$root" 2>/dev/null; then
    echo "error: Firstmate temp root $root exists but is not a private directory owned by this user, or could not be created; inspect and remove it, then retry" >&2
    return 1
  fi
}

fm_task_tmp_dir() {  # <task-id>
  printf '%s/fm-%s' "$(fm_tmp_root)" "$1"
}

fm_task_launch_dir() {  # <task-id> <home-token>
  printf '%s/fm-%s+%s' "$(fm_tmp_root)" "$1" "$2"
}
