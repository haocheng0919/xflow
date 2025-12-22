# XFlow

**Immersive information flow for your desktop.**

XFlow is a macOS native application that brings a "Danmaku" (barrage) style ticker of Twitter/X feeds directly to your desktop. It allows you to stay updated with real-time market intelligence, social updates, and crypto signals without breaking your workflow.

![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![Platform](https://img.shields.io/badge/Platform-macOS%2014%2B-lightgrey.svg)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

## Features

- **BYOK (Bring Your Own Key)**: You control your data. No subscription fees, no central server. Connect directly to Twitter via RapidAPI or official Twitter API.
- **Non-Intrusive Danmaku**: Tweets float across your screen like a video comment stream.
    - **Smart Hover**: Hover over a tweet to pause it and see details.
    - **Click-Through**: Click background areas to interact with windows behind the text.
- **Web3 Enhanced**: Automatically detects Contract Addresses (CA) for Solana and EVM chains.
    - One-click jump to trading terminals like GMGN, Axiom, or Photon.
- **Bento Style Dashboard**: beautiful, grid-based control panel to manage sources and settings.
- **Highly Customizable**: Adjust speed, opacity, fonts, and screen regions (Top/Middle/Bottom).

## Installation

### Prerequisites
- macOS 14.0 (Sonoma) or later.
- Xcode 15+ (to build from source).

### Build from Source
1. Clone the repository:
   ```bash
   git clone https://github.com/haocheng0919/xflow.git
   cd xflow
   ```

2. Open the project in Xcode or build via swift:
   ```bash
   swift build -c release
   ```

3. Run the application:
   ```bash
   swift run
   ```

## Configuration

XFlow uses a **Bring Your Own Key** model. You need API access to fetch tweets.

### 1. Environment Setup (Recommended)
Create a `.env` file in the root directory to preload your keys:

```bash
cp .env.example .env
```

Edit `.env` and add your keys:
```env
# Option 1: RapidAPI (Recommended for cost/ease)
RAPIDAPI_KEY=your_rapidapi_key_here

# Option 2: Twitter Official API
BEARER_TOKEN=your_twitter_bearer_token_here
```

### 2. Dashboard Setup
Alternatively, you can enter your keys directly in the App Dashboard under 'Inputs & Keys'.

## Usage

- **Dashboard**: Press the dashboard button in the menu bar or use the global shortcut (default: `,`) to open the settings grid.
- **Sources**: Add Twitter lists, user handles, or search queries (e.g., "$BTC", "#SwiftUI").
- **Control**: Toggle the flow Start/Stop from the menu bar.

## Security

- **Local Execution**: All logic runs locally on your machine.
- **Key Safety**: API keys are stored in your local UserDefaults (or loaded from `.env` at runtime) and are never sent to any third-party server besides the API provider (Twitter/RapidAPI).

## License

This project is licensed under the MIT License.