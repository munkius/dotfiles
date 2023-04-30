install_plugin() {
  local plugin_name=$1 version=$2 repo=$3

  if test $(asdf plugin list | grep -Fx "$plugin_name")
  then
    read -p "  $plugin_name is already installed. Would you like to update? (Y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]
    then
      asdf plugin update $plugin_name
    fi
  else
    echo "› Installing $plugin_name..."
    asdf plugin-add $plugin_name $repo
    asdf install $plugin_name $version
    asdf global $plugin_name $version
  fi
}

install_cocoapods() {
  echo "› Installing cocoapods..."
  gem install cocoapods
}

install_plugin "flutter" "latest"
install_plugin "ruby" "latest" "https://github.com/asdf-vm/asdf-ruby.git"
install_cocoapods
