import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../config/mapbox_config.dart';

class MapboxMapWidget extends StatefulWidget {
  final Point initialPosition;
  final double zoom;
  final void Function(MapboxMap)? onMapCreated;
  final void Function(MapboxMap)? onStyleLoaded;

  const MapboxMapWidget({
    Key? key,
    required this.initialPosition,
    this.zoom = 12.0,
    this.onMapCreated,
    this.onStyleLoaded,
  }) : super(key: key);

  @override
  _MapboxMapWidgetState createState() => _MapboxMapWidgetState();
}

class _MapboxMapWidgetState extends State<MapboxMapWidget> {
  MapboxMap? _controller;

  void _onMapCreated(MapboxMap mapboxMap) {
    print('[MapboxMapWidget] Map created!');
    _controller = mapboxMap;
    if (widget.onMapCreated != null) {
      widget.onMapCreated!(mapboxMap);
    }
  }

  @override
  Widget build(BuildContext context) {
    print('[MapboxMapWidget] Building MapWidget...');
    print('[MapboxMapWidget] Access token: ${MapboxConfig.accessToken}');
    print('[MapboxMapWidget] Initial position: ${widget.initialPosition}');
    print('[MapboxMapWidget] Zoom: ${widget.zoom}');
    return MapWidget(
      key: ValueKey("mapWidget"),
      cameraOptions: CameraOptions(
        center: widget.initialPosition,
        zoom: widget.zoom,
      ),
      styleUri: MapboxStyles.MAPBOX_STREETS,
      onMapCreated: _onMapCreated,
      onMapLoadErrorListener: (error) {
        print('[MapboxMapWidget] Map load error: ${error.message}');
      },
      onMapLoadedListener: (event) {
        print('[MapboxMapWidget] Map loaded successfully!');
      },
      onStyleLoadedListener: (event) {
        print('[MapboxMapWidget] Map style loaded!');
        if (widget.onStyleLoaded != null && _controller != null) {
          widget.onStyleLoaded!(_controller!);
        }
      },
    );
  }
} 