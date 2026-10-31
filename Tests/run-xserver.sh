#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
build=$(mktemp -d /tmp/loginpanel-xserver-tests-XXXXXX)
trap 'rm -rf "$build"' EXIT HUP INT TERM
${CC:-clang} $(gnustep-config --objc-flags) -I. '-DDEFAULT_XSERVER={"Xvfb",":99","-screen","0","800x600x24","-nolisten","tcp",NULL}' Tests/xserver.m XServerManager.m -o "$build/xserver" $(gnustep-config --gui-libs) -lX11 -lXau
"$build/xserver"
