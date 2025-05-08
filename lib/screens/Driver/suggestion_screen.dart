import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_google_maps_webservices/directions.dart' as directions;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'profile_screen.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class SuggestionScreen extends StatefulWidget {
  final String riderName;

  SuggestionScreen({required this.riderName});

  @override
  _SuggestionScreenState createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  final String apiKey = 'AIzaSyCdeeHhTXFdiPxVbunjt1mrHvdKalajkVg';
  bool isMapLoading = true;
  bool areIconsLoaded = false;
  String mapError = '';
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  String rideInfo = 'Calculating...';
  BitmapDescriptor? startIcon;
  BitmapDescriptor? pickupIcon;
  BitmapDescriptor? endIcon;

  Map<String, Map<String, dynamic>> riderDetails = {
    'Shayna S.': {
      'pickupLocation': 'Schönbühlstraße 90, 70188 Stuttgart, Allemagne',
      'pickupTime': '8:07',
      'department': 'Finance',
      'preferences': ['Prefers quiet rides', 'Pets don’t bother me'],
      'distance': 'I’m flexible within pick-up location',
    },
    'Michael B.': {
      'pickupLocation': 'Hamburg, Germany',
      'pickupTime': '8:15',
      'department': 'IT',
      'preferences': ['Broken downjust fodo', 'I’m free long'],
      'distance': 'I’m flexible within pick-up location',
    },
    'Alex A.': {
      'pickupLocation': 'Frankfurt, Germany',
      'pickupTime': '17:12',
      'department': 'Marketing',
      'preferences': ['Fast to coaims wito', 'I’m long farfire nm'],
      'distance': 'I’m flexible within pick-up location',
    },
  };

  final String startAddress = 'Epplestraße 18, 70597 Stuttgart, Allemagne';
  String endAddress = 'Andreas-Stihl-Straße 4, 71336 Waiblingen, Allemagne';

  @override
  void initState() {
    super.initState();
    print('SuggestionScreen: initState called');
    _initializeIconsAndMap();
  }

  Future<void> _initializeIconsAndMap() async {
    print('SuggestionScreen: Starting initialization of icons and map');
    await _loadCustomIcons();
    if (mounted) {
      print('SuggestionScreen: Icons loaded, proceeding to fetch route and map');
      await _fetchRouteAndMap();
    } else {
      print('SuggestionScreen: Widget not mounted, skipping fetchRouteAndMap');
    }
  }

  Future<void> _loadCustomIcons() async {
    print('SuggestionScreen: Loading custom icons...');
    try {
      startIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(30, 30)),
        'assets/icons/car.png',
      );
      print('SuggestionScreen: Start icon loaded');
      pickupIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(30, 30)),
        'assets/icons/person_pin.png',
      );
      print('SuggestionScreen: Pickup icon loaded');
      endIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(30, 30)),
        'assets/icons/destination.png',
      );
      print('SuggestionScreen: End icon loaded');
      setState(() {
        areIconsLoaded = true;
      });
      print('SuggestionScreen: Custom icons loaded successfully');
    } catch (e) {
      print('SuggestionScreen: Error loading custom icons: $e');
      startIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      pickupIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      endIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      setState(() {
        areIconsLoaded = true;
      });
    }
  }

  Future<void> _fetchRouteAndMap() async {
    if (!areIconsLoaded) {
      print('SuggestionScreen: Icons not yet loaded, waiting...');
      return;
    }

    print('SuggestionScreen: Fetching route and map...');
    setState(() {
      isMapLoading = true;
      mapError = '';
      rideInfo = 'Calculating...';
    });

    final directionsApi = directions.GoogleMapsDirections(apiKey: apiKey);
    final riderInfo = riderDetails[widget.riderName]!;
    final pickupLocation = riderInfo['pickupLocation'];

    print('SuggestionScreen: Fetching route from $startAddress to $endAddress via $pickupLocation');

    try {
      final response = await directionsApi.directionsWithAddress(
        startAddress,
        endAddress,
        waypoints: [directions.Waypoint.fromAddress(pickupLocation)],
      ).timeout(Duration(seconds: 10), onTimeout: () {
        throw Exception('Request timed out');
      });

      print('SuggestionScreen: Directions API Response: ${response.toJson()}');

      if (!response.isOkay) {
        print('SuggestionScreen: API Error: ${response.errorMessage}');
        setState(() {
          mapError = 'Failed to load route: ${response.errorMessage ?? "Unknown error"}';
          isMapLoading = false;
        });
        return;
      }

      if (response.routes.isEmpty) {
        print('SuggestionScreen: No routes found');
        setState(() {
          mapError = 'No routes available';
          isMapLoading = false;
        });
        return;
      }

      final route = response.routes[0];
      print('SuggestionScreen: Route found: ${route.summary}');

      if (route.overviewPolyline == null || route.overviewPolyline!.points == null) {
        print('SuggestionScreen: No polyline data available');
        setState(() {
          mapError = 'No route polyline available';
          isMapLoading = false;
        });
        return;
      }

      final legs = route.legs;
      if (legs.isEmpty || legs.length < 2) {
        print('SuggestionScreen: Invalid route legs: $legs');
        setState(() {
          mapError = 'Invalid route legs';
          isMapLoading = false;
        });
        return;
      }

      num totalDurationSeconds = 0;
      num totalDistanceMeters = 0;

      for (var leg in legs) {
        totalDurationSeconds += leg.duration?.value ?? 0;
        totalDistanceMeters += leg.distance?.value ?? 0;
      }

      final totalDurationMinutes = (totalDurationSeconds / 60).toInt();
      final totalDistanceKm = (totalDistanceMeters / 1000).toStringAsFixed(1);

      String durationText;
      if (totalDurationMinutes >= 60) {
        final hours = totalDurationMinutes ~/ 60;
        final minutes = totalDurationMinutes % 60;
        durationText = '$hours hr $minutes mins';
      } else {
        durationText = '$totalDurationMinutes mins';
      }

      setState(() {
        rideInfo = '$durationText • $totalDistanceKm km';
      });

      final polylinePoints = _decodePolyline(route.overviewPolyline!.points!);
      print('SuggestionScreen: Decoded polyline points: $polylinePoints');

      setState(() {
        _polylines.clear();
        _polylines.add(Polyline(
          polylineId: PolylineId('route'),
          points: polylinePoints,
          color: Color(0xFF0288D1),
          width: 5,
        ));
      });

      final startLatLng = LatLng(legs[0].startLocation.lat, legs[0].startLocation.lng);
      final pickupLatLng = LatLng(legs[0].endLocation.lat, legs[0].endLocation.lng);
      final endLatLng = LatLng(legs[1].endLocation.lat, legs[1].endLocation.lng);

      setState(() {
        _markers.clear();
        _markers.add(Marker(
          markerId: MarkerId('start'),
          position: startLatLng,
          infoWindow: InfoWindow(title: 'Start: $startAddress'),
          icon: startIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ));
        _markers.add(Marker(
          markerId: MarkerId('pickup'),
          position: pickupLatLng,
          infoWindow: InfoWindow(title: 'Pickup: $pickupLocation'),
          icon: pickupIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ));
        _markers.add(Marker(
          markerId: MarkerId('end'),
          position: endLatLng,
          infoWindow: InfoWindow(title: 'End: $endAddress'),
          icon: endIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ));
      });

      if (route.bounds != null) {
        final neLat = route.bounds!.northeast.lat;
        final neLng = route.bounds!.northeast.lng;
        final swLat = route.bounds!.southwest.lat;
        final swLng = route.bounds!.southwest.lng;

        final bounds = LatLngBounds(
          northeast: LatLng(neLat, neLng),
          southwest: LatLng(swLat, swLng),
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngBounds(bounds, 50),
            );
            print('SuggestionScreen: Camera updated to bounds: $bounds');
          } else {
            print('SuggestionScreen: Map controller not initialized yet');
          }
        });
      } else {
        print('SuggestionScreen: Route bounds are null');
      }

      setState(() {
        isMapLoading = false;
      });
    } catch (e, stackTrace) {
      print('SuggestionScreen: Exception caught: $e');
      print('SuggestionScreen: Stack trace: $stackTrace');
      setState(() {
        mapError = 'Error loading map: $e';
        rideInfo = 'Error calculating ride info';
        isMapLoading = false;
      });
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
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

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
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
      });
      print('SuggestionScreen: Updated ${isPickup ? 'pickup' : 'drop-off'} location to: $newAddress');

      await _fetchRouteAndMap();
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

  void _onMapTap() {
    print('SuggestionScreen: Map tapped');
    if (mapError.isNotEmpty) {
      print('SuggestionScreen: Map tap ignored due to error: $mapError');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenMap(
          polylines: _polylines,
          markers: _markers,
          initialBounds: _mapController != null && _polylines.isNotEmpty
              ? LatLngBounds(
                  northeast: LatLng(
                    _polylines.first.points.map((p) => p.latitude).reduce(math.max),
                    _polylines.first.points.map((p) => p.longitude).reduce(math.max),
                  ),
                  southwest: LatLng(
                    _polylines.first.points.map((p) => p.latitude).reduce(math.min),
                    _polylines.first.points.map((p) => p.longitude).reduce(math.min),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('SuggestionScreen: Building UI');
    final riderInfo = riderDetails[widget.riderName]!;
    print('SuggestionScreen: Rider info retrieved: $riderInfo');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Suggestion (Driver)',
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
            print('SuggestionScreen: Back button pressed');
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
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _onMapTap,
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
                          child: isMapLoading
                              ? Center(child: CircularProgressIndicator())
                              : mapError.isNotEmpty
                                  ? Center(child: Text(mapError, textAlign: TextAlign.center))
                                  : GoogleMap(
                                      onMapCreated: (controller) {
                                        print('SuggestionScreen: Map created');
                                        _mapController = controller;
                                        if (_polylines.isNotEmpty) {
                                          final bounds = LatLngBounds(
                                            northeast: LatLng(
                                              _polylines.first.points.map((p) => p.latitude).reduce(math.max),
                                              _polylines.first.points.map((p) => p.longitude).reduce(math.max),
                                            ),
                                            southwest: LatLng(
                                              _polylines.first.points.map((p) => p.latitude).reduce(math.min),
                                              _polylines.first.points.map((p) => p.longitude).reduce(math.min),
                                            ),
                                          );
                                          controller.animateCamera(
                                            CameraUpdate.newLatLngBounds(bounds, 50),
                                          );
                                          print('SuggestionScreen: Camera updated to bounds: $bounds');
                                        }
                                      },
                                      initialCameraPosition: CameraPosition(
                                        target: LatLng(48.766667, 9.183333),
                                        zoom: 10,
                                      ),
                                      polylines: _polylines,
                                      markers: _markers,
                                      zoomControlsEnabled: false,
                                      myLocationEnabled: false,
                                      myLocationButtonEnabled: false,
                                      mapToolbarEnabled: false,
                                    ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        rideInfo,
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
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
                                          riderInfo['pickupLocation'],
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
                                    onPressed: () => _editAddress(riderInfo['pickupLocation'], true),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.remove_red_eye, color: Colors.grey[600], size: 20),
                                    onPressed: () => _launchGoogleMaps(riderInfo['pickupLocation']),
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
                                    riderInfo['pickupTime'],
                                    style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.grey[600], size: 20),
                                    onPressed: () => _editPickupTime(riderInfo['pickupTime']),
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
                                    ...riderInfo['preferences'].map<Widget>((pref) {
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
                                            riderInfo['distance'],
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
}

class FullScreenMap extends StatefulWidget {
  final Set<Polyline> polylines;
  final Set<Marker> markers;
  final LatLngBounds? initialBounds;

  FullScreenMap({required this.polylines, required this.markers, this.initialBounds});

  @override
  _FullScreenMapState createState() => _FullScreenMapState();
}

class _FullScreenMapState extends State<FullScreenMap> {
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    print('FullScreenMap: initState called');
  }

  @override
  Widget build(BuildContext context) {
    print('FullScreenMap: Building UI');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Route Map',
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
            print('FullScreenMap: Back button pressed');
            Navigator.pop(context);
          },
        ),
      ),
      body: GoogleMap(
        onMapCreated: (controller) {
          print('FullScreenMap: Map created');
          _mapController = controller;
          if (widget.initialBounds != null) {
            controller.animateCamera(
              CameraUpdate.newLatLngBounds(widget.initialBounds!, 50),
            );
            print('FullScreenMap: Camera updated to bounds: ${widget.initialBounds}');
          }
        },
        initialCameraPosition: CameraPosition(
          target: LatLng(48.766667, 9.183333),
          zoom: 30,
        ),
        polylines: widget.polylines,
        markers: widget.markers,
        zoomControlsEnabled: true,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        mapToolbarEnabled: false,
      ),
    );
  }
}