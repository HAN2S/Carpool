import 'dart:convert';
import 'package:carpool_test/services/mapbox_service.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:math' as math;

import '../../../widgets/mapbox_map_widget.dart';
import '../../config/mapbox_config.dart';
import 'profile_screen.dart';

class SuggestionScreen extends StatefulWidget {
  final String riderName;

  SuggestionScreen({required this.riderName});

  @override
  _SuggestionScreenState createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  MapboxMap? _controller;
  bool isMapLoading = true;
  String mapError = '';
  String rideInfo = 'Calculating route...';
  int mapReloadKey = 0;

  Map<String, Map<String, dynamic>> riderDetails = {
    'Shayna S.': {
      'pickupLocation': 'Schönbühlstraße 90, 70188 Stuttgart, Allemagne',
      'pickupTime': '8:07',
      'department': 'Finance',
      'preferences': ['Prefers quiet rides', "Pets don't bother me"],
      'distance': "I'm flexible within pick-up location",
    },
    'Michael B.': {
      'pickupLocation': 'Hamburg, Germany',
      'pickupTime': '8:15',
      'department': 'IT',
      'preferences': ['Broken downjust fodo', "I'm free long"],
      'distance': "I'm flexible within pick-up location",
    },
    'Alex A.': {
      'pickupLocation': 'Frankfurt, Germany',
      'pickupTime': '17:12',
      'department': 'Marketing',
      'preferences': ['Fast to coaims wito', "I'm long farfire nm"],
      'distance': "I'm flexible within pick-up location",
    },
  };

  final String startAddress = 'Epplestraße 18, 70597 Stuttgart, Allemagne';
  String endAddress = 'Andreas-Stihl-Straße 4, 71336 Waiblingen, Allemagne';

  // We will store the resolved coordinates here
  Point? _startPoint;
  Point? _endPoint;
  Point? _pickupPoint;
  bool _markersReady = false;

  @override
  void initState() {
    super.initState();
    print('[SuggestionScreen] initState called');
    _resolveRideCoordinates();
  }

  Future<void> _resolveRideCoordinates() async {
    // Geocode the addresses to coordinates
    final startAddress = this.startAddress;
    final pickupAddress = riderDetails[widget.riderName]!['pickupLocation'];
    final endAddress = this.endAddress;
    try {
      print('Geocoding start: $startAddress');
      final startLocations = await locationFromAddress(startAddress);
      print('Start geocoded: ${startLocations.first.latitude}, ${startLocations.first.longitude}');
      print('Geocoding pickup: $pickupAddress');
      final pickupLocations = await locationFromAddress(pickupAddress);
      print('Pickup geocoded: ${pickupLocations.first.latitude}, ${pickupLocations.first.longitude}');
      print('Geocoding end: $endAddress');
      final endLocations = await locationFromAddress(endAddress);
      print('End geocoded: ${endLocations.first.latitude}, ${endLocations.first.longitude}');
      setState(() {
        _startPoint = Point(coordinates: Position(startLocations.first.longitude, startLocations.first.latitude));
        _pickupPoint = Point(coordinates: Position(pickupLocations.first.longitude, pickupLocations.first.latitude));
        _endPoint = Point(coordinates: Position(endLocations.first.longitude, endLocations.first.latitude));
        _markersReady = true;
      });
    } catch (e) {
      print('Error geocoding ride addresses: $e');
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    print('[SuggestionScreen] Map created!');
    _controller = mapboxMap;
  }

  Future<Point?> _getCoordinates(String address) async {
    print('[SuggestionScreen] Geocoding address: $address');
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        print('[SuggestionScreen] Geocoded to: ${location.latitude}, ${location.longitude}');
        return Point(coordinates: Position(location.longitude, location.latitude));
      }
    } catch (e) {
      print('[SuggestionScreen] Error geocoding address "$address": $e');
    }
    return null;
  }

  Future<void> _getCoordinatesAndDrawRoute() async {
    print('[SuggestionScreen] Getting coordinates and drawing route...');
    setState(() {
      isMapLoading = true;
      mapError = '';
    });

    final riderPickupAddress = riderDetails[widget.riderName]!['pickupLocation'];
    print('[SuggestionScreen] Pickup address: $riderPickupAddress');

    _startPoint = Point(coordinates: Position(9.1770, 48.7823)); // Stuttgart
    _pickupPoint = Point(coordinates: Position(9.183333, 48.766667)); // Stuttgart
    _endPoint = Point(coordinates: Position(9.3164, 48.8328)); // Waiblingen

    print('[SuggestionScreen] Start: $_startPoint, Pickup: $_pickupPoint, End: $_endPoint');

    if (_startPoint == null || _pickupPoint == null || _endPoint == null) {
      print('[SuggestionScreen] One or more coordinates are null!');
      setState(() {
        mapError = 'Could not find coordinates for one or more addresses.';
        isMapLoading = false;
      });
      return;
    }

    setState(() {
      rideInfo = '';
      isMapLoading = false;
    });
  }

  Future<List<Uint8List>> _loadMarkerImages() async {
    final ByteData carBytes = await rootBundle.load('assets/icons/car.png');
    final ByteData startBytes = await rootBundle.load('assets/icons/person_pin.png');
    final ByteData endBytes = await rootBundle.load('assets/icons/destination.png');
    return [
      carBytes.buffer.asUint8List(),
      startBytes.buffer.asUint8List(),
      endBytes.buffer.asUint8List(),
    ];
  }

  Future<List<Position>> _fetchRoutePolyline(Position start, Position pickup, Position end) async {
    final accessToken = MapboxConfig.accessToken;
    final coordinates = '${start.lng},${start.lat};${pickup.lng},${pickup.lat};${end.lng},${end.lat}';
    final url = 'https://api.mapbox.com/directions/v5/mapbox/driving/$coordinates?geometries=polyline&access_token=$accessToken';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final polyline = data['routes'][0]['geometry'];
      return _decodePolyline(polyline);
    } else {
      throw Exception('Failed to fetch route');
    }
  }

  List<Position> _decodePolyline(String encoded) {
    List<Position> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      poly.add(Position(lng / 1E5, lat / 1E5));
    }
    return poly;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Suggestion Info',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Card(
                elevation: 4,
                color: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: _markersReady && _startPoint != null && _pickupPoint != null && _endPoint != null
                        ? FutureBuilder<List<Uint8List>>(
                            future: _loadMarkerImages(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                              final carImageBytes = snapshot.data![0];
                              final startImageBytes = snapshot.data![1];
                              final endImageBytes = snapshot.data![2];
                              return Stack(
                                children: [
                                  MapboxMapWidget(
                                    key: ValueKey('mapWithMarker'),
                                    initialPosition: _pickupPoint!,
                                    zoom: 10,
                                    onMapCreated: (mapboxMap) async {
                                      _controller = mapboxMap;
                                      await _addMarkers();
                                    },
                                  ),
                                  Positioned.fill(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onTap: () {
                                        print('Tapped!');
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => FullscreenMapScreen(
                                              startPoint: _startPoint!,
                                              pickupPoint: _pickupPoint!,
                                              endPoint: _endPoint!,
                                              carImageBytes: carImageBytes,
                                              startImageBytes: startImageBytes,
                                              endImageBytes: endImageBytes,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(),
                                    ),
                                  ),
                                ],
                              );
                            },
                          )
                        : Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Card(
                        elevation: 0,
                        color: Colors.grey[100],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pick-up Location',
                                          style: GoogleFonts.roboto(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          riderDetails[widget.riderName]!['pickupLocation'],
                                          style: GoogleFonts.roboto(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.grey[600], size: 20),
                                    onPressed: () => _editAddress(riderDetails[widget.riderName]!['pickupLocation'], true),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.remove_red_eye, color: Colors.grey[600], size: 20),
                                    onPressed: () => _launchGoogleMaps(riderDetails[widget.riderName]!['pickupLocation']),
                                  ),
                                ],
                              ),
                              Divider(color: Colors.grey[300], thickness: 1),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Drop-off Location',
                                          style: GoogleFonts.roboto(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          endAddress,
                                          style: GoogleFonts.roboto(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.grey[600], size: 20),
                                    onPressed: () => _editAddress(endAddress, false),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.remove_red_eye, color: Colors.grey[600], size: 20),
                                    onPressed: () => _launchGoogleMaps(endAddress),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Card(
                        elevation: 0,
                        color: Colors.grey[100],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Pick-up Time',
                                      style: GoogleFonts.roboto(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    riderDetails[widget.riderName]!['pickupTime'],
                                    style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.grey[600], size: 20),
                                    onPressed: () => _editPickupTime(riderDetails[widget.riderName]!['pickupTime']),
                                  ),
                                ],
                              ),
                              Divider(color: Colors.grey[300], thickness: 1),
                              GestureDetector(
                                onTap: () {
                                  print('SuggestionScreen: Navigating to ProfileScreen');
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => ProfileScreen()),
                                  );
                                },
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: Colors.green[100],
                                          child: Text(
                                            widget.riderName[0],
                                            style: GoogleFonts.roboto(
                                              fontSize: 16,
                                              color: Colors.green,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            widget.riderName,
                                            style: GoogleFonts.roboto(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.phone, color: Colors.green),
                                          onPressed: () {
                                            print('SuggestionScreen: Phone button pressed');
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.message, color: Colors.green),
                                          onPressed: () {
                                            print('SuggestionScreen: Message button pressed');
                                          },
                                        ),
                                      ],
                                    ),
                                    ...riderDetails[widget.riderName]!['preferences'].map<Widget>((pref) {
                                      return Padding(
                                        padding: EdgeInsets.only(left: 28, bottom: 4),
                                        child: Row(
                                          children: [
                                            Icon(
                                              pref.contains('quiet') ? Icons.volume_off : Icons.pets,
                                              color: Colors.grey[600],
                                              size: 16,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              pref,
                                              style: GoogleFonts.roboto(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    Padding(
                                      padding: EdgeInsets.only(left: 28),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.directions,
                                            color: Colors.grey[600],
                                            size: 16,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            riderDetails[widget.riderName]!['distance'],
                                            style: GoogleFonts.roboto(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        print('SuggestionScreen: Accept button pressed');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Accept',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        print('SuggestionScreen: Reject button pressed');
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Reject',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchGoogleMaps(String address) async {
    print('SuggestionScreen: Launching Google Maps for address: $address');
    final url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('SuggestionScreen: Could not launch $url');
    }
  }

  Future<void> _editAddress(String address, bool isPickup) async {
    print('SuggestionScreen: Editing address, isPickup: $isPickup, current address: $address');
    TextEditingController addressController = TextEditingController(text: address);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isPickup ? 'Edit Pickup Location' : 'Edit Drop-off Location'),
          content: TextField(
            controller: addressController,
            decoration: InputDecoration(
              labelText: isPickup ? 'Pickup Location' : 'Drop-off Location',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                print('SuggestionScreen: Edit address dialog - Cancel pressed');
                Navigator.pop(context, false);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (addressController.text.trim().isEmpty) {
                  print('SuggestionScreen: Edit address dialog - Empty address, showing snackbar');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid address')),
                  );
                  return;
                }
                print('SuggestionScreen: Edit address dialog - Save pressed');
                Navigator.pop(context, true);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final newAddress = addressController.text.trim();
      setState(() {
        if (isPickup) {
          riderDetails[widget.riderName]!['pickupLocation'] = newAddress;
        } else {
          endAddress = newAddress;
        }
        mapReloadKey++;
      });
      print('SuggestionScreen: Updated ${isPickup ? 'pickup' : 'drop-off'} location to: $newAddress');
    }
  }

  Future<void> _editPickupTime(String currentTime) async {
    print('SuggestionScreen: Editing pickup time, current time: $currentTime');
    final timeParts = currentTime.split(':');
    final initialHour = int.parse(timeParts[0]);
    final initialMinute = int.parse(timeParts[1]);

    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      final formattedTime = '${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}';
      print('SuggestionScreen: Selected pickup time: $formattedTime');

      setState(() {
        riderDetails[widget.riderName]!['pickupTime'] = formattedTime;
      });
    } else {
      print('SuggestionScreen: No time selected');
    }
  }

  Future<void> _addMarkers() async {
    print('Map created, adding markers...');
    // Load the images from assets
    final ByteData carBytes = await rootBundle.load('assets/icons/car.png');
    final Uint8List carImageBytes = carBytes.buffer.asUint8List();
    final ByteData startBytes = await rootBundle.load('assets/icons/person_pin.png');
    final Uint8List startImageBytes = startBytes.buffer.asUint8List();
    final ByteData endBytes = await rootBundle.load('assets/icons/destination.png');
    final Uint8List endImageBytes = endBytes.buffer.asUint8List();
    // Create the marker manager
    final pointManager = await _controller!.annotations.createPointAnnotationManager();
    // Add the pickup (car) marker
    print('Adding pickup marker at: [32m${_pickupPoint!.coordinates}[0m');
    await pointManager.create(
      PointAnnotationOptions(
        geometry: _pickupPoint!,
        image: carImageBytes,
        iconSize: 0.5,
      ),
    );
    // Add the start marker
    print('Adding start marker at: [34m${_startPoint!.coordinates}[0m');
    await pointManager.create(
      PointAnnotationOptions(
        geometry: _startPoint!,
        image: startImageBytes,
        iconSize: 0.5,
      ),
    );
    // Add the end marker
    print('Adding end marker at: [31m${_endPoint!.coordinates}[0m');
    await pointManager.create(
      PointAnnotationOptions(
        geometry: _endPoint!,
        image: endImageBytes,
        iconSize: 0.5,
      ),
    );
    // Draw the polyline route
    try {
      final polylinePositions = await _fetchRoutePolyline(
        _startPoint!.coordinates,
        _pickupPoint!.coordinates,
        _endPoint!.coordinates,
      );
      final polylineManager = await _controller!.annotations.createPolylineAnnotationManager();
      await polylineManager.create(
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: polylinePositions),
          lineColor: 0xFF007AFF,
          lineWidth: 8.0,
        ),
      );
      // Calculate bounds
      double minLat = polylinePositions.first.lat.toDouble(), maxLat = polylinePositions.first.lat.toDouble();
      double minLng = polylinePositions.first.lng.toDouble(), maxLng = polylinePositions.first.lng.toDouble();
      for (final pos in polylinePositions) {
        if (pos.lat < minLat) minLat = pos.lat.toDouble();
        if (pos.lat > maxLat) maxLat = pos.lat.toDouble();
        if (pos.lng < minLng) minLng = pos.lng.toDouble();
        if (pos.lng > maxLng) maxLng = pos.lng.toDouble();
      }
      // Center and zoom to fit bounds (approximate)
      await _controller!.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(((minLng + maxLng) / 2).toDouble(), ((minLat + maxLat) / 2).toDouble())),
          zoom: 9.5, // You can adjust this value for best fit
        ),
        MapAnimationOptions(duration: 1500),
      );
      print('Route polyline drawn.');
    } catch (e) {
      print('Error drawing route polyline: $e');
    }
  }
}

class FullscreenMapScreen extends StatelessWidget {
  final Point startPoint;
  final Point pickupPoint;
  final Point endPoint;
  final Uint8List carImageBytes;
  final Uint8List startImageBytes;
  final Uint8List endImageBytes;

  const FullscreenMapScreen({
    required this.startPoint,
    required this.pickupPoint,
    required this.endPoint,
    required this.carImageBytes,
    required this.startImageBytes,
    required this.endImageBytes,
    Key? key,
  }) : super(key: key);

  Future<List<Position>> _fetchRoutePolyline(Position start, Position pickup, Position end) async {
    final accessToken = MapboxConfig.accessToken;
    final coordinates = '${start.lng},${start.lat};${pickup.lng},${pickup.lat};${end.lng},${end.lat}';
    final url = 'https://api.mapbox.com/directions/v5/mapbox/driving/$coordinates?geometries=polyline&access_token=$accessToken';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final polyline = data['routes'][0]['geometry'];
      return _decodePolyline(polyline);
    } else {
      throw Exception('Failed to fetch route');
    }
  }

  List<Position> _decodePolyline(String encoded) {
    List<Position> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      poly.add(Position(lng / 1E5, lat / 1E5));
    }
    return poly;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            MapboxMapWidget(
              key: ValueKey('fullscreenMap'),
              initialPosition: pickupPoint,
              zoom: 12,
              onMapCreated: (mapboxMap) async {
                final pointManager = await mapboxMap.annotations.createPointAnnotationManager();
                await pointManager.create(PointAnnotationOptions(
                  geometry: pickupPoint,
                  image: carImageBytes,
                  iconSize: 0.5,
                ));
                await pointManager.create(PointAnnotationOptions(
                  geometry: startPoint,
                  image: startImageBytes,
                  iconSize: 0.5,
                ));
                await pointManager.create(PointAnnotationOptions(
                  geometry: endPoint,
                  image: endImageBytes,
                  iconSize: 0.5,
                ));
                // Draw the polyline route
                try {
                  final polylinePositions = await _fetchRoutePolyline(
                    startPoint.coordinates,
                    pickupPoint.coordinates,
                    endPoint.coordinates,
                  );
                  final polylineManager = await mapboxMap.annotations.createPolylineAnnotationManager();
                  await polylineManager.create(
                    PolylineAnnotationOptions(
                      geometry: LineString(coordinates: polylinePositions),
                      lineColor: 0xFF007AFF,
                      lineWidth: 8.0,
                    ),
                  );
                  // Calculate bounds
                  double minLat = polylinePositions.first.lat.toDouble(), maxLat = polylinePositions.first.lat.toDouble();
                  double minLng = polylinePositions.first.lng.toDouble(), maxLng = polylinePositions.first.lng.toDouble();
                  for (final pos in polylinePositions) {
                    if (pos.lat < minLat) minLat = pos.lat.toDouble();
                    if (pos.lat > maxLat) maxLat = pos.lat.toDouble();
                    if (pos.lng < minLng) minLng = pos.lng.toDouble();
                    if (pos.lng > maxLng) maxLng = pos.lng.toDouble();
                  }
                  // Center and zoom to fit bounds (approximate)
                  await mapboxMap.flyTo(
                    CameraOptions(
                      center: Point(coordinates: Position(((minLng + maxLng) / 2).toDouble(), ((minLat + maxLat) / 2).toDouble())),
                      zoom: 9.5,
                    ),
                    MapAnimationOptions(duration: 1500),
                  );
                  print('Route polyline drawn (fullscreen).');
                } catch (e) {
                  print('Error drawing route polyline (fullscreen): $e');
                }
              },
            ),
            Positioned(
              top: 16,
              left: 16,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}