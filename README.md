# SpeedTestBar

A native macOS menu bar app that continuously monitors your internet speed and logs results with GPS coordinates.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange?logo=swift)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **📊 Menu Bar Indicator** — Shows your current download speed (e.g. `↓ 85 Mbps`) right in the macOS menu bar
- **🔄 Auto-Refresh** — Runs a speed test automatically every 5 minutes
- **👆 Click to Test** — Click the menu bar item to trigger an immediate speed test
- **📍 Location Tracking** — Captures GPS coordinates with each test so you can compare speeds at different locations
- **📋 Historical Log** — View all past results in a sortable table with download, upload, ping, and coordinates
- **📤 CSV Export** — Export your history to CSV for analysis in Excel, Google Sheets, etc.

## Screenshot

| Menu Bar | History Window |
|----------|---------------|
| `↓ 85 Mbps` in your menu bar | Full table with timestamp, speeds, ping, lat/lng |

## Installation

### Prerequisites

- macOS 14.0 (Sonoma) or later
- Swift 5.9+ (included with Xcode Command Line Tools)

```bash
# Install Xcode Command Line Tools if needed
xcode-select --install
```

### Build & Run

```bash
git clone https://github.com/DanielGoodwyn/speed-test-bar.git
cd speed-test-bar
chmod +x build_app.sh
./build_app.sh
open SpeedTestBar.app
```

### Install to Applications

```bash
cp -r SpeedTestBar.app /Applications/
```

## How It Works

1. **Speed Test** — Downloads a 25MB file from Cloudflare's speed test CDN and measures throughput. Also runs upload (5MB) and ping tests.
2. **Location** — Uses CoreLocation to capture your lat/lng at the time of each test. macOS will prompt for location permission on first run.
3. **Storage** — Results are saved as JSON to `~/Library/Application Support/SpeedTestBar/history.json`

## Menu Bar

The menu bar shows your latest download speed. Click it to see:

- **Run Speed Test** — Trigger a test immediately
- **View History** — Open the history window
- **Last Test Summary** — Download, upload, ping, location, and time ago
- **Quit**

## Data Format

Each test result contains:

| Field | Type | Description |
|-------|------|-------------|
| `timestamp` | ISO 8601 | When the test was run |
| `downloadMbps` | Double | Download speed in Mbps |
| `uploadMbps` | Double | Upload speed in Mbps |
| `pingMs` | Double | Latency in milliseconds |
| `latitude` | Double? | GPS latitude (nil if permission denied) |
| `longitude` | Double? | GPS longitude (nil if permission denied) |

## Tech Stack

- **Swift** with Swift Package Manager (no Xcode project required)
- **AppKit** — `NSStatusItem` for the menu bar
- **SwiftUI** — History window with sortable `Table`
- **CoreLocation** — GPS coordinates
- **URLSession** — Speed test against Cloudflare CDN
- **Codable** — JSON persistence

## License

MIT
