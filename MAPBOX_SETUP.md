# Mapbox API Setup Guide

This guide will help you set up Mapbox API for the carpool app.

## Prerequisites

1. A Mapbox account (free tier available)
2. Flutter development environment

## Step 1: Get Mapbox Access Token

1. Go to [Mapbox Account](https://account.mapbox.com/)
2. Sign up or log in to your account
3. Navigate to "Access Tokens" in your account dashboard
4. Create a new token or copy your default public token
5. Make sure the token has the following scopes:
   - `styles:read`
   - `styles:tiles`
   - `geocoding`

## Step 2: Configure the App

1. Open `lib/config/mapbox_config.dart`
2. Replace `YOUR_MAPBOX_ACCESS_TOKEN` with your actual Mapbox access token:

```dart
static const String accessToken = 'pk.your_actual_token_here';
```

## Step 3: Install Dependencies

Run the following command to install the new dependencies:

```bash
flutter pub get
```

## Step 4: Platform Configuration

### Android

1. Open `android/app/src/main/AndroidManifest.xml`
2. Add the following permissions if not already present:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS

1. Open `ios/Runner/Info.plist`
2. Add the following keys if not already present:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to location to find your current address.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs access to location to find your current address.</string>
```

## Step 5: Test the Integration

1. Run the app: `flutter run`
2. Navigate to the onboarding screen
3. Test the address search functionality
4. Test the "Use My Current Location" feature

## Features Available

With Mapbox integration, your app now supports:

- **Address Search**: Users can search for addresses with autocomplete
- **Reverse Geocoding**: Convert GPS coordinates to human-readable addresses
- **Current Location**: Automatically detect and display user's current location
- **Country Filtering**: Search results are filtered by country (Germany by default)

## Troubleshooting

### Common Issues

1. **"No suggestions found"**: Check your Mapbox access token and internet connection
2. **Location permission denied**: Ensure location permissions are properly configured
3. **API rate limits**: Mapbox has rate limits on free tier accounts

### Debug Information

The app includes debug logging. Check the console output for:
- Location permission status
- API request/response details
- Error messages

## Cost Considerations

- Mapbox offers a generous free tier (50,000 map loads per month)
- Geocoding API calls are included in the free tier
- Monitor your usage in the Mapbox dashboard

## Next Steps

Consider implementing:
- Map display using `mapbox_gl` package
- Route optimization using Mapbox Directions API
- Real-time location tracking
- Offline map support 