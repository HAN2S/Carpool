import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapboxService {
  final String _accessToken;
  final String _baseUrl = 'https://api.mapbox.com';

  MapboxService({required String accessToken}) : _accessToken = accessToken;

  /// Search for places using Mapbox Geocoding API
  Future<List<MapboxPlace>> searchPlaces(String query, {String? country}) async {
    try {
      final countryFilter = country != null ? '&country=$country' : '';
      final url = '$_baseUrl/geocoding/v5/mapbox.places/$query.json?access_token=$_accessToken&types=poi,address&limit=5$countryFilter';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;
        
        return features.map((feature) => MapboxPlace.fromJson(feature)).toList();
      } else {
        print('Error searching places: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception searching places: $e');
      return [];
    }
  }

  /// Get place details using coordinates
  Future<MapboxPlace?> getPlaceDetails(double latitude, double longitude) async {
    try {
      final url = '$_baseUrl/geocoding/v5/mapbox.places/$longitude,$latitude.json?access_token=$_accessToken&types=poi,address&limit=1';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;
        
        if (features.isNotEmpty) {
          return MapboxPlace.fromJson(features.first);
        }
      } else {
        print('Error getting place details: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exception getting place details: $e');
    }
    return null;
  }

  /// Reverse geocoding - get address from coordinates
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final url = '$_baseUrl/geocoding/v5/mapbox.places/$longitude,$latitude.json?access_token=$_accessToken&types=poi,address&limit=1';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;
        
        if (features.isNotEmpty) {
          final feature = features.first;
          return feature['place_name'] as String?;
        }
      } else {
        print('Error reverse geocoding: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exception reverse geocoding: $e');
    }
    return null;
  }

  /// Get directions (route) between multiple points
  Future<Map<String, dynamic>?> getDirections(List<dynamic> points) async {
    try {
      final coordinates = points.map((p) {
        if (p is Point) {
          return "${p.coordinates.lng},${p.coordinates.lat}";
        } else if (p is List && p.length == 2) {
          return "${p[0]},${p[1]}";
        } else {
          throw Exception("Invalid point format");
        }
      }).join(';');
      final url = '$_baseUrl/directions/v5/mapbox/driving/$coordinates?geometries=geojson&access_token=$_accessToken';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error fetching directions: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception fetching directions: $e');
      return null;
    }
  }
}

class MapboxPlace {
  final String id;
  final String placeName;
  final String text;
  final List<double> coordinates;
  final Map<String, dynamic> properties;
  final Map<String, dynamic> context;

  MapboxPlace({
    required this.id,
    required this.placeName,
    required this.text,
    required this.coordinates,
    required this.properties,
    required this.context,
  });

  factory MapboxPlace.fromJson(Map<String, dynamic> json) {
    final coordinates = (json['center'] as List).cast<double>();
    return MapboxPlace(
      id: json['id'] as String,
      placeName: json['place_name'] as String,
      text: json['text'] as String,
      coordinates: coordinates,
      properties: json['properties'] as Map<String, dynamic>? ?? {},
      context: json['context'] as Map<String, dynamic>? ?? {},
    );
  }

  double get latitude => coordinates[1];
  double get longitude => coordinates[0];
} 