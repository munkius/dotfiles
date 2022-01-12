
install_dart() {
  echo "› Installing dart..."
  asdf plugin-add dart https://github.com/patoconnor43/asdf-dart.git
  asdf install dart 2.15.1
  asdf global dart 2.15.1
}

install_flutter() {
  echo "› Installing flutter..."
  asdf plugin-add flutter
  asdf install flutter 2.8.1
  asdf global flutter 2.8.1
}

install_cocoapods() {
  echo "› Installing cocoapods..."
  asdf plugin-add ruby https://github.com/asdf-vm/asdf-ruby.git
  asdf install ruby 3.1.0
  asdf global ruby 3.1.0
  gem install cocoapods
}

install_dart
install_flutter
install_cocoapods
