# A simple Timer app for Mac

<img src="/screenshots/light-mode.png?raw=true" width="262" align="right">

<img src="/screenshots/dark-mode.png?raw=true" width="262" align="right">

[Download here](https://github.com/michaelvillar/timer-app/releases)

Drag the blue arrow to set a timer. Release to start! Click to pause.

When the time is up, a notification will show up with a nice sound.

Create new timers with `CMD+N`.

Install as a [brew cask](https://caskroom.github.io) via

```shell
brew install --cask michaelvillar-timer
```

Inspired by the **great** [Minutes widget](http://minutes.en.softonic.com/mac) from Nitram-nunca I've been using for years. But it wasn't maintained anymore (non-retina) + it was the only widget in my dashboard :)

Timer requires macOS 10.11 or later.

## Changes

### v1.7.0

- **🚀 CLI Integration**: Added command-line interface support for Timer.app
- **⚡ Auto-start Option**: New `--start` flag to automatically begin timers
- **🔧 GUI Launcher**: `timer-launch` CLI tool to launch Timer.app with preset times
- **📱 Multiple Execution Methods**:
  - `timer-launch --time 19:30 --start` (GUI launcher)
  - `open -a Timer.app --args --time 19:30 --start` (macOS open command)
  - Direct execution from app bundle: `Timer.app/Contents/MacOS/timer-launch`
- **🎯 Multiple Instance Support**: Run multiple timers simultaneously
- **📦 Integrated Build**: CLI tools automatically included in app bundle
- **⏰ Flexible Time Setting**:
  - Specific time: `--time 14:30`
  - Duration in minutes: `--duration 25`
  - Duration in seconds: `--seconds 1800`
- **🔧 Enhanced Makefile**: Automated build process for GUI + CLI integration

### Build

```
make
```

### CLI Usage (v1.7.0+)

Launch Timer.app with preset times from command line:

```bash
# Set timer for specific time and auto-start
timer-launch --time 19:30 --start

# Set timer for 25 minutes and auto-start  
timer-launch --duration 25 --start

# Using macOS open command
open -a Timer.app --args --time 14:30 --start

# Multiple timers simultaneously
timer-launch --duration 10 --start  # Timer 1
timer-launch --duration 15 --start  # Timer 2
```

Install CLI tools system-wide:

```bash
make launcher-install
```

For more CLI options, see [README-CLI.md](README-CLI.md).

### Keyboard Shortcuts

Enter digits to set minutes. A decimal point specifies seconds so `2.34` is 2 minutes and 34 seconds.

<kbd>backspace</kbd> or <kbd>escape</kbd> to edit.
<kbd>enter</kbd> to start or pause the timer.
<kbd>cmd</kbd>+<kbd>n</kbd> to create a new timer.
<kbd>r</kbd> to restart with the last timer.
