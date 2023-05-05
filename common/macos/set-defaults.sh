# # Heavily inspired by https://github.com/mathiasbynens/dotfiles/blob/master/.macos

echo "› Setting up Mac defaults"

# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

###############################################################################
# Global                                                                      #
###############################################################################

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

###############################################################################
# Finder                                                                      #
###############################################################################

# Remove duplicates in the “Open With” menu (also see `lscleanup` alias)
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user

###############################################################################
# Trackpad, mouse, keyboard, Bluetooth accessories, and input                 #
###############################################################################

# Keyboard: set a blazingly fast keyboard repeat rate
defaults write -g InitialKeyRepeat -int 15
defaults write -g KeyRepeat -int 2

# Trackpad: enable tap to click for this user and for the login screen
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
sudo defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
sudo defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
sudo defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Trackpad: enable double tap to drag
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Dragging -int 1
defaults write com.apple.AppleMultitouchTrackpad Dragging -int 1

echo "Be sure to restart your Mac for the trackpad changed to take effect"

###############################################################################
# Finder                                                                      #
###############################################################################
# Set column view
defaults write com.apple.finder "FXPreferredViewStyle" -string "clmv" && killall Finder

###############################################################################
# Dock, Dashboard, and hot corners                                            #
###############################################################################

# Backup for if we fucked it up :)
# defaults delete com.apple.dock; killall Dock

# Enable highlight hover effect for the grid view of a stack (Dock)
defaults write com.apple.dock mouse-over-hilite-stack -bool true

# Set the icon size of Dock items to 36 pixels
defaults write com.apple.dock tilesize -int 36

# Change minimize/maximize window effect
defaults write com.apple.dock mineffect -string "scale"

# Minimize windows into their application’s icon
defaults write com.apple.dock minimize-to-application -bool true

# Dock magnification
defaults write com.apple.dock largesize -int 90
defaults write com.apple.dock magnification -bool true

# Enable spring loading for all Dock items
defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true

# Show indicator lights for open applications in the Dock
defaults write com.apple.dock show-process-indicators -bool true

# Wipe all (default) app icons from the Dock
# This is only really useful when setting up a new Mac, or if you don’t use
# the Dock to launch apps.
defaults write com.apple.dock persistent-apps -array

# Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool true

# Run the screensaver if we're in the bottom-left hot corner.
defaults write com.apple.dock wvous-bl-corner -int 5
defaults write com.apple.dock wvous-bl-modifier -int 0

# Do not keep recently opened apps in the dock
defaults write com.apple.dock show-recents -int 0

# Restart the dock
killall Dock
