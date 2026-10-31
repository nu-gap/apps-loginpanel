#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
build=$(mktemp -d /tmp/loginpanel-tests-XXXXXX)
trap 'rm -rf "$build"' EXIT HUP INT TERM
${CC:-clang} $(gnustep-config --objc-flags) -I. Tests/authentication.m Authenticator.m -o "$build/authentication" $(gnustep-config --gui-libs) -lcrypt
"$build/authentication"
${CC:-clang} $(gnustep-config --objc-flags) -I. Tests/session.m LoginPanelController.m Authenticator.m XServerManager.m -o "$build/session" $(gnustep-config --gui-libs) -lcrypt -lX11 -lXau
"$build/session"
${CC:-clang} $(gnustep-config --objc-flags) loginpaneld.m -o "$build/loginpaneld" $(gnustep-config --base-libs)
python3 Tests/supervisor.py "$build/loginpaneld"
