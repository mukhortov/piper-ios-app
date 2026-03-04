<p align="center">
  <img src="https://www.apple.com/v/app-store/c/images/overview/icon_appstore__ev0z770zyxoy_large_2x.png" width="130">
  <a href="https://testflight.apple.com/join/Adkg5F5H">
    <img src="PiperApp/Resources/piper_apple_app_logo.png" width="130">
  </a>
</p>


<h3 align="center">
  Piper for iOS is here! 🚀 Our Public Beta is officially live and we want your feedback. 
  Be among the first to experience high-quality local TTS on your iPhone. 
  <a href="https://testflight.apple.com/join/Adkg5F5H">Join the Beta today! ✨</a>
</h3>

# 📥 Cloning & Building Piper

## System Requirements

* iOS 17.0+
* macOS 14.0+
* Xcode 16+
* `mise`
* Git LFS

---

## Getting the Sources

```bash
git clone https://github.com/IhorShevchuk/piper-app.git
cd piper-app
```

---

## Install Toolchain (via mise)

Piper uses `mise` to manage development tools.

Install mise

```bash
curl https://mise.run | sh
```

Then install tools:

```bash
mise install
```

This installs:

* Tuist
* SwiftLint
* Git LFS

---

## Git LFS

```bash
mise run lfs
```

---

## Generate the Xcode Project

Piper uses **Tuist**. Generate the workspace:

```bash
mise run generate
```

Open the generated `.xcworkspace` in Xcode.

---

# 📱 Running the App

## Simulator

1. Open the generated workspace
2. Select an iOS Simulator
3. Build & Run `Piper`

---

## Physical Device

1. Open the generated workspace
2. Select your device
3. Configure code signing for:
   * `Piper`
   * `PiperTTS`