#!/bin/sh -x -e

# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Ihor Shevchuk

if  [ "$1" == "--fix" ] && [ ! -z "$CI_BUILD" ]; then
   echo "No automatic fixing on CI! Skipping"
   exit 0
fi

if [ "$ENABLE_PREVIEWS" = "YES" ] ; then
   echo "No automatic fixing during SwiftUI preview build! Skipping"
   exit 0
fi


if which mise >/dev/null; then
  mise install
  mise use swiftlint
  mise exec -- swiftlint $1 --reporter ${REPORTER:-xcode} --config $(dirname "$0")/swiftlint.yml
else
   # If mise was installed via brew it is needed to make symbolic lynk from mise in brew path to system path:
   # You may use next command to do this:
   # sudo ln -s /opt/homebrew/bin/mise /usr/local/bin/
   echo "warning: mise not installed"
fi
