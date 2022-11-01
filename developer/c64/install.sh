#!/bin/sh
#
# As inspired from https://github.com/springload/dotfiles/blob/master/config/visual-studio-code/install.sh

function install_extensions() {
  echo "Be sure to download the latest C64 debugger from https://sourceforge.net/projects/c64-debugger/files/latest/download"
  echo "and to place the C64 Debugger app into the /Applications folder."
  local extensions=(
    "rosc.vs64"
  )

  for extension in "${extensions[@]}"
  do
    code --install-extension $extension
  done
}

function update_settings() {
  local SETTINGS_FILE="$HOME/Library/Application Support/Code/User/settings.json"
  local SETTINGS='  "c64.debuggerPath": "/Applications/C64 Debugger.app/Contents/MacOS/C64 Debugger",\n  "c64.assemblerPath": "/usr/local/bin/acme",\n  "c64.emulatorPath": "/usr/local/bin/x64sc",'

  if ! [[ $(grep "c64." "$SETTINGS_FILE") ]]
  then
    local NEW_SETTINGS_CONTENT=$(printf '$i\n%s\n.\n,p\n', "$SETTINGS" | ed -s "$SETTINGS_FILE")
    echo "$NEW_SETTINGS_CONTENT" > $SETTINGS_FILE
  fi
}

if test $(which code)
then
  update_settings
fi


