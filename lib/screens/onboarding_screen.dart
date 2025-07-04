import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart' as geocoding;
import '../services/mapbox_service.dart';
import '../config/mapbox_config.dart';
import 'dart:async';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String? selectedRole;
  final TextEditingController _homeAddressController = TextEditingController();
  final TextEditingController _workAddressController = TextEditingController();
  final loc.Location _location = loc.Location();
  late MapboxService _mapboxService;
  bool _isHomeDropdownVisible = false;
  bool _isWorkDropdownVisible = false;
  String? _currentLocation;
  double? _homeLatitude;
  double? _homeLongitude;
  double? _workLatitude;
  double? _workLongitude;
  List<MapboxPlace> _homeSuggestions = [];
  List<MapboxPlace> _workSuggestions = [];
  final FocusNode _homeFocusNode = FocusNode();
  final FocusNode _workFocusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _mapboxService = MapboxService(accessToken: MapboxConfig.accessToken);
    _homeFocusNode.addListener(() {
      setState(() {
        _isHomeDropdownVisible = _homeFocusNode.hasFocus;
      });
    });
    _workFocusNode.addListener(() {
      setState(() {
        _isWorkDropdownVisible = _workFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _homeAddressController.dispose();
    _workAddressController.dispose();
    _homeFocusNode.dispose();
    _workFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _requestLocationPermission() async {
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return false;
      }
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        return false;
      }
    }

    return true;
  }

  Future<String?> _getCurrentLocation() async {
    try {
      print('Requesting location permission...');
      final hasPermission = await _requestLocationPermission();
      if (!hasPermission) {
        print('Location permission denied');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permission denied')),
        );
        return null;
      }

      print('Getting location data...');
      final locationData = await _location.getLocation();
      final latitude = locationData.latitude;
      final longitude = locationData.longitude;

      if (latitude == null || longitude == null) {
        print('Failed to get latitude or longitude');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location coordinates')),
        );
        return null;
      }

      print('Location retrieved: ($latitude, $longitude)');
      setState(() {
        _homeLatitude = latitude;
        _homeLongitude = longitude;
        _workLatitude = latitude;
        _workLongitude = longitude;
      });

      print('Fetching address from coordinates using Mapbox...');
      final address = await _mapboxService.getAddressFromCoordinates(latitude, longitude);
      if (address != null) {
        print('Address from coordinates: $address');
        return address;
      } else {
        print('No address found for coordinates');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not determine address from coordinates')),
        );
        return null;
      }
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
      return null;
    }
  }

  Future<void> _fetchCurrentLocation() async {
    print('Fetching current location...');
    final location = await _getCurrentLocation();
    if (location != null) {
      print('Current location set: $location');
      setState(() {
        _currentLocation = location;
      });
    } else {
      print('Failed to fetch current location');
    }
  }

  Future<void> _fetchSuggestions(String input, bool isHomeField) async {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (input.isEmpty) {
        setState(() {
          if (isHomeField) {
            _homeSuggestions = [];
          } else {
            _workSuggestions = [];
          }
        });
        return;
      }

      try {
        final suggestions = await _mapboxService.searchPlaces(input, country: MapboxConfig.defaultCountry);

        setState(() {
          if (isHomeField) {
            _homeSuggestions = suggestions;
          } else {
            _workSuggestions = suggestions;
          }
        });
      } catch (e) {
        print('Error fetching suggestions: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching suggestions: $e')),
        );
      }
    });
  }

  Future<void> _fetchPlaceDetails(String placeId, bool isHomeField) async {
    try {
      // For Mapbox, we need to find the place by ID from our suggestions
      final suggestions = isHomeField ? _homeSuggestions : _workSuggestions;
      final place = suggestions.firstWhere((place) => place.id == placeId);
      
      if (place != null) {
        setState(() {
          if (isHomeField) {
            _homeLatitude = place.latitude;
            _homeLongitude = place.longitude;
            print("Home Coordinates: ($_homeLatitude, $_homeLongitude)");
          } else {
            _workLatitude = place.latitude;
            _workLongitude = place.longitude;
            print("Work Coordinates: ($_workLatitude, $_workLongitude)");
          }
        });
      } else {
        print('No location data found for place ID: $placeId');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No location data found for this place')),
        );
      }
    } catch (e) {
      print('Error fetching place details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching place details: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pendla', style: Theme.of(context).textTheme.headlineSmall),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Let's get started by entering your details", style: TextStyle(fontSize: 16)),
              SizedBox(height: 20),
              Text('Route Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Stack(
                children: [
                  TextField(
                    controller: _homeAddressController,
                    focusNode: _homeFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Enter your home address',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      suffixIcon: Icon(Icons.home),
                    ),
                    onTap: () {
                      print('Home field tapped');
                      _homeFocusNode.requestFocus();
                      _fetchCurrentLocation();
                    },
                    onChanged: (value) {
                      _fetchSuggestions(value, true);
                    },
                  ),
                  if (_isHomeDropdownVisible)
                    Positioned(
                      top: 60,
                      left: 0,
                      right: 0,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              if (_currentLocation != null)
                                ListTile(
                                  title: Text('Use My Current Location'),
                                  subtitle: Text(_currentLocation!),
                                  onTap: () {
                                    _homeAddressController.text = _currentLocation!;
                                    setState(() {
                                      _isHomeDropdownVisible = false;
                                      _homeSuggestions = [];
                                    });
                                    _homeFocusNode.unfocus();
                                  },
                                ),
                              ..._homeSuggestions.map((suggestion) => ListTile(
                                    title: Text(suggestion.placeName),
                                    onTap: () {
                                      _homeAddressController.text = suggestion.placeName;
                                      setState(() {
                                        _isHomeDropdownVisible = false;
                                        _homeSuggestions = [];
                                      });
                                      _homeFocusNode.unfocus();
                                      _fetchPlaceDetails(suggestion.id, true);
                                    },
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 20),
              Stack(
                children: [
                  TextField(
                    controller: _workAddressController,
                    focusNode: _workFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Enter your work address',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      suffixIcon: Icon(Icons.work),
                    ),
                    onTap: () {
                      _fetchCurrentLocation();
                    },
                    onChanged: (value) {
                      _fetchSuggestions(value, false);
                    },
                  ),
                  if (_isWorkDropdownVisible)
                    Positioned(
                      top: 60,
                      left: 0,
                      right: 0,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              if (_currentLocation != null)
                                ListTile(
                                  title: Text('Use My Current Location'),
                                  subtitle: Text(_currentLocation!),
                                  onTap: () {
                                    _workAddressController.text = _currentLocation!;
                                    setState(() {
                                      _isWorkDropdownVisible = false;
                                      _workSuggestions = [];
                                    });
                                    _workFocusNode.unfocus();
                                  },
                                ),
                              ..._workSuggestions.map((suggestion) => ListTile(
                                    title: Text(suggestion.placeName),
                                    onTap: () {
                                      _workAddressController.text = suggestion.placeName;
                                      setState(() {
                                        _isWorkDropdownVisible = false;
                                        _workSuggestions = [];
                                      });
                                      _workFocusNode.unfocus();
                                      _fetchPlaceDetails(suggestion.id, false);
                                    },
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 20),
              Text('Select Your Role', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Driver'),
                      value: 'Driver',
                      groupValue: selectedRole,
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Passenger'),
                      value: 'Passenger',
                      groupValue: selectedRole,
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text('Choose Your Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/weekly_schedule');
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Schedules', style: TextStyle(color: Colors.grey)),
                      Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/driver_information');
                },
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: Text('Submit', style: Theme.of(context).textTheme.labelLarge),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}