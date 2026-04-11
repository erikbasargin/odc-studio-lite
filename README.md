<p align="center">
    <img alt="ODC Lite logo" src="https://github.com/erikbasargin/odc-studio-lite/blob/main/ODCLite/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-256.png" />
</p>

<p align="center">
    <img alt="macOS 26.0+" src="https://img.shields.io/badge/macOS-26.0%2B-blue">
    <img alt="swift 6.3+" src="https://img.shields.io/badge/swift-6.3%2B-blue">
</p>

ODC Lite is a macOS menu bar app for capturing a display, mixing optional camera and microphone input, and sending the result to Twitch over RTMP.

## Overview

When ODC Lite launches, it configures screen capture, opens the system content-sharing picker for display selection, and requests camera access when needed. The app keeps its primary controls in the menu bar so you can switch devices and start or stop a broadcast without opening a full window.

Use the menu bar interface to:

- Choose a camera from the available built-in and Continuity Camera devices.
- Choose a microphone to include in the outgoing stream.
- Enable Twitch bandwidth testing before going live.
- Start or stop a broadcast after entering a primary stream key in Settings.

Open Settings to provide the Twitch primary stream key required before broadcasting.

## Automation

ODC Lite also exposes App Shortcuts for microphone control:

- Start capturing microphone
- Stop capturing microphone

These shortcuts let you automate voice capture with Shortcuts, Siri, or system search without opening the menu bar menu.
