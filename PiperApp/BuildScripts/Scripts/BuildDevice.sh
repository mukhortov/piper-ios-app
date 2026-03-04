#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Ihor Shevchuk

BUILD_NUMBER=$1

rm -fr BuildOutput

echo "BUILD_NUMBER=${BUILD_NUMBER}"

export BUILD_NUMBER

xcodebuild clean archive \
  -configuration "Release" \
  -target Piper \
  -scheme Piper \
  -allowProvisioningUpdates \
  -archivePath "BuildOutput/Piper.xcarchive" \
  -destination "generic/platform=iOS"

xcodebuild -exportArchive \
  -allowProvisioningUpdates \
  -archivePath "BuildOutput/Piper.xcarchive" \
  -exportPath "BuildOutput/binary/iOS" \
  -exportOptionsPlist "PiperApp/BuildScripts/Configs/iOSExportOptions.plist"
