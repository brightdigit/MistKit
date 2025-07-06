# MistKit Demo

A comprehensive demo application that showcases MistKit's CloudKit Web Services capabilities with built-in authentication.

## Features

- **Web-based Authentication**: Automatically starts a local web server for CloudKit authentication
- **Sign in with Apple ID**: Uses CloudKit JS for secure authentication
- **Automatic Token Capture**: Captures the session token and uses it for API calls
- **CloudKit Operations Demo**: Demonstrates fetching user info, listing zones, and querying records
- **Skip Authentication Mode**: Reuse tokens for faster testing

## Prerequisites

1. An Apple Developer account
2. A CloudKit container configured in your Apple Developer account
3. CloudKit API Token generated for your container

## Setup

1. Update your CloudKit credentials in the command or in the HTML file:
   - Container identifier (e.g., `iCloud.com.example.app`)
   - API token from Apple Developer portal

2. Build and run:
   ```bash
   cd Examples
   swift build
   swift run mistdemo --container-identifier "iCloud.com.example.app" --api-token "YOUR_API_TOKEN"
   ```

## How It Works

1. **Server Start**: The demo starts a local Hummingbird web server
2. **Browser Opens**: Your browser automatically opens to the authentication page
3. **Sign In**: Click "Sign In with Apple ID" and authenticate
4. **Token Capture**: The server captures your session token
5. **Demo Runs**: CloudKit operations are performed automatically
6. **Results Display**: See your user info, zones, and records in the terminal

## Command Line Options

```bash
swift run mistdemo --help
```

### Options:
- `-c, --container-identifier`: Your CloudKit container ID
- `-a, --api-token`: Your CloudKit API token
- `--host`: Server host (default: 127.0.0.1)
- `-p, --port`: Server port (default: 8080)
- `--skip-auth`: Skip authentication server
- `--web-auth-token`: Provide token directly (use with --skip-auth)

## Usage Examples

### First Run (with authentication):
```bash
swift run mistdemo \
  --container-identifier "iCloud.com.example.app" \
  --api-token "YOUR_API_TOKEN"
```

### Subsequent Runs (skip authentication):
```bash
swift run mistdemo \
  --container-identifier "iCloud.com.example.app" \
  --api-token "YOUR_API_TOKEN" \
  --skip-auth \
  --web-auth-token "SESSION_TOKEN_FROM_FIRST_RUN"
```

## What the Demo Does

1. **Fetches Current User**: Displays your CloudKit user information
2. **Lists Zones**: Shows all zones in your private database
3. **Queries Records**: Attempts to query "TestRecord" type records

## Security Notes

- The authentication token is only valid for a limited time
- Never commit your API token to version control
- Use environment variables for production deployments
- The web server only runs locally on your machine

## Troubleshooting

If authentication fails:
1. Verify your container identifier matches exactly
2. Ensure your API token is valid and has proper permissions
3. Check that you're signed into iCloud on your device
4. Make sure you've accepted the CloudKit permissions prompt

## Project Structure

```
Examples/
├── Package.swift
├── README.md
└── Sources/
    └── MistDemo/
        ├── MistDemo.swift      # Main application
        ├── CloudKitService.swift  # CloudKit API wrapper
        └── Resources/
            └── index.html      # Authentication web page
```