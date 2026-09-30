#!/bin/sh
set -e

# Le .xcodeproj est généré par XcodeGen (ignoré par git) : on le régénère sur Xcode Cloud.
cd "$CI_PRIMARY_REPOSITORY_PATH"
export HOMEBREW_NO_AUTO_UPDATE=1
brew install xcodegen
xcodegen generate
