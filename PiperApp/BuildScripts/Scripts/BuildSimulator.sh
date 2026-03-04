#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Ihor Shevchuk

BUILD_NUMBER="${1:-0}"

xcodebuild build \
  -scheme Piper \
  -configuration "Release" \
  -sdk iphonesimulator \
  -destination "generic/platform=iOS Simulator" \
  CODE_SIGNING_ALLOWED=NO \
  ONLY_ACTIVE_ARCH=YES \
  COPY_PHASE_STRIP=NO \
  STRIP_INSTALLED_PRODUCT=NO \
  DEPLOYMENT_POSTPROCESSING=NO

