# The Brewfile handles Homebrew-based app and library installs, but there may
# still be updates and installables in the Mac App Store. There's a nifty
# command line interface to it that we can use to just install everything, so
# yeah, let's do that.


ask_macos_update() {
  read -p "Do you want to upgrade your MacOS? (Y/N): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
      echo "› sudo softwareupdate -i -a"
      sudo softwareupdate -i -a
  fi
}

set_macos_defaults() {
  CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
  $CURRENT_DIR/set-defaults.sh
}

ask_macos_update
set_macos_defaults
