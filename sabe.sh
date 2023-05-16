#!/bin/sh
set -eou pipefail

# Functions
check_or_create() {
  [ -e $2.txt ] || ls $1 | sort | cat > $2.txt
}

# if bin records do not exist, record them
init_lists() {
  check_or_create /bin/ bin
  check_or_create /usr/bin/ usr_bin
  check_or_create /usr/local/bin/ usr_local_bin
  check_or_create ~/.local/share/applications local_share_applications
  check_or_create ~/.local/share/apps local_share_apps
  # TODO: system .desktop files
}

export_bin() {
  echo exporting bin $app
}
export_app() {
  echo exporting app $app
}

export_new_apps_from() {
  ls $1 | sort | comm -23 - $2.txt | \
  while IFS= read -r app; do
    # echo "Text read from file: $app"
    case "$app" in
      *.desktop) export_app "$1/$app"
      ;;
      *) export_bin "$1/$app"
      ;;
    esac
  done
}

export_new_apps() {
  export_new_apps_from /usr/local/bin/ usr_local_bin
  export_new_apps_from /usr/bin/ usr_bin
  export_new_apps_from /bin/ bin
  export_new_apps_from ~/.local/share/applications local_share_applications
  export_new_apps_from ~/.local/share/apps local_share_apps
}

run_cmd() {
  # execute underlying command (if it exists)
  if type $1 &>/dev/null ; then
    $@
  else
    echo "command not found: $1"
    return 0 #1
  fi
}

# execution start
case "$1" in
  dnf|apt*|pacman|apk)
    init_lists
    run_cmd $@
    case "$2" in
      install|add|-S|-Sy|-Su|-Syu)
        export_new_apps
      ;;
      # TODO: extend for export removal
    esac
  ;;
  *) echo unknown package manager
  ;;
esac
