# Wipe

A dead-simple macOS app to clean your MacBook screen and keyboard.

Screen goes full black (or white, red, green, blue) at maximum brightness so you can spot every smudge. Keyboard is completely locked so you can wipe without triggering random shortcuts.

## Features

- **Full-screen cleaning mode** — solid color fills the entire display, including under the notch
- **Max brightness** — automatically cranks brightness to 100% to reveal smudges, restores your original level on exit
- **Keyboard lock** — all keyboard input is suppressed via a system-level event tap
- **Color cycling** — click anywhere to cycle through black → white → red → green → blue (different colors reveal different types of marks)
- **Hold to unlock** — hold `fn` + `Return` for 7 seconds to exit (progress bar shows countdown)
- **Cleaning timer** — subtle elapsed time display in the corner
- **Instructions fade-out** — on-screen hints disappear after 5 seconds
- **Unlock sound** — audible "Glass" feedback when you unlock

## Install

### Requirements

- macOS 14 (Sonoma) or later
- Xcode Command Line Tools (`xcode-select --install`)

### Build & Install

```bash
git clone https://github.com/fexxdev/Wipe.git
cd Wipe
make install
```

This builds a release binary, packages it into `Wipe.app`, signs it with an ad-hoc signature, and copies it to `/Applications`.

To just build without installing:

```bash
make bundle    # creates Wipe.app in the project directory
make run       # builds and opens the app
```

### Granting Accessibility Access

Wipe needs **Accessibility permissions** to lock your keyboard. macOS will prompt you the first time, but if you need to do it manually:

1. Open **System Settings**
2. Go to **Privacy & Security → Accessibility**
3. Click the **+** button (you may need to unlock with your password)
4. Navigate to `/Applications/Wipe.app` (or wherever you placed it) and add it
5. Make sure the toggle next to **Wipe** is **ON**

> Without Accessibility access the app will launch, but the keyboard won't lock during cleaning — the "Start Cleaning" button stays disabled until permissions are granted.

If you run via `swift run` during development, you'll need to grant access to your **Terminal** app (or iTerm, Warp, etc.) instead.

## Usage

1. Launch **Wipe** from Applications (or `make run`)
2. Click **Start Cleaning**
3. The screen goes full-screen black at max brightness
4. Clean your screen and keyboard
5. **Click** anywhere to cycle through colors and spot different marks
6. When done, **hold `fn` + `Return` for 7 seconds** — a green progress bar appears at the bottom
7. The app unlocks, plays a sound, restores your brightness, and returns to the home screen

## Development

```bash
swift build              # debug build
swift run                # build and run (debug)
make bundle              # release .app bundle
make clean               # remove build artifacts
```

### Regenerate the app icon

```bash
pip3 install Pillow
python3 scripts/generate_icon.py
```

## Privacy & Analytics

Wipe collects **completely anonymous** usage stats purely for fun — we just like seeing how much collective screen-cleaning the community does.

What's collected (when enabled):
- A launch counter (no device ID, no IP, no fingerprinting)
- Cleaning session duration

What's **never** collected:
- Personal information of any kind
- Device identifiers or IP addresses
- Anything that could identify you

You can **disable analytics entirely** from the Stats panel (click the chart icon in the app). When disabled, zero network requests are made.

The stats are visible to everyone in the app's "Community" section — total launches, active users today, and global cleaning time across all Wipe users.

## How it works

| Component | What it does |
|-----------|-------------|
| `KeyboardManager` | Creates a `CGEvent` tap at the session level to intercept and suppress all keyboard events. Monitors for the fn + Return unlock combo. |
| `BrightnessManager` | Uses the private `DisplayServices` framework (loaded via `dlopen`) to save, maximize, and restore screen brightness. Fails gracefully on unsupported displays. |
| `AppState` | Central state management — coordinates cleaning mode, timer, color cycling, and keyboard/brightness managers. |
| `CleaningView` | Full-screen SwiftUI view with color fill, fade-out instructions, timer, and unlock progress bar. |

## License

MIT
