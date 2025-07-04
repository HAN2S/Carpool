import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapboxConfig {
  static String get accessToken {
    final token = dotenv.env['MAPBOX_ACCESS_TOKEN'];
    if (token == null || token.isEmpty) {
      throw Exception('MAPBOX_PUBLIC_TOKEN not found in .env file');
    }
    return token;
  }

  // Mapbox style URL (optional - for map display)
  static const String mapStyle = 'mapbox://styles/mapbox/streets-v11';
  
  // Default country code for search (Germany in this case)
  static const String defaultCountry = 'de';
} 