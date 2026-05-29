install_tool() {
  local tool_name=$1 version=$2

  echo "› Installing $tool_name@$version via mise..."
  mise use --global "$tool_name@$version"
}

install_cocoapods() {
  echo "› Installing cocoapods..."
  gem install cocoapods
}

link_android_studio_java() {
  local my_link="/Library/Java/JavaVirtualMachines/android-studio-jree"
  if [ ! -L ${my_link} ] || [ ! -e ${my_link} ]
  then
    echo "› Linking JDK from Android Studio..."
    sudo ln -s "/Applications/Android Studio.app/Contents/jbr" ${my_link}
  fi
}

install_tool "flutter" "latest"
install_tool "ruby" "latest"
install_cocoapods
link_android_studio_java
