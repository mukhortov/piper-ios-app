#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Ihor Shevchuk

if [ "$ACTION" != "install" ]; then
    echo "skip fixing onnxframework as action is $ACTION"
    exit 0
fi

echo "trying to fix onnxframework as action is $ACTION"

FRAMEWORKS_DIR="$BUILT_PRODUCTS_DIR/$FRAMEWORKS_FOLDER_PATH"

MINIMUM_OS_VERSION="100.0"
find "$FRAMEWORKS_DIR" -path "*.framework/Info.plist" | while read -r plist; do
  if ! /usr/libexec/PlistBuddy -c "Print :MinimumOSVersion" "$plist" &>/dev/null; then
    echo "Adding MinimumOSVersion to $plist"
    /usr/libexec/PlistBuddy -c "Add :MinimumOSVersion string $MINIMUM_OS_VERSION" "$plist"
  fi
done
