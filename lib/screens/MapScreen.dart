import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _currentPosition;
  final LatLng _defaultLocation = const LatLng(32.905268, 13.227581); // Tripoli
  LatLng? _selectedMarker;
  String _directions = "";
  List<LatLng> _route = [];
  bool _isLoading = false;

  // List of blood bank locations (replace with your actual data)
  final List<LatLng> _bloodBanks = [
    const LatLng(32.8925, 13.1708), // Example blood bank 1
    const LatLng(32.8950, 13.2350), // Example blood bank 2
    const LatLng(32.9100, 13.2400), // Example blood bank 3
  ];

  final MapController _mapController = MapController();
  final Distance _distanceCalculator = const Distance();

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      _mapController.move(_currentPosition!, 13.0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to get current location")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getDirections(LatLng origin, LatLng destination) async {
    setState(() {
      _isLoading = true;
      _directions = "Calculating route...";
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/'
          '${origin.longitude},${origin.latitude};'
          '${destination.longitude},${destination.latitude}?overview=full&steps=true',
        ),
      );

      final data = json.decode(response.body);

      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final legs = route['legs'][0];
        final steps = legs['steps'];

        // Extract route coordinates
        final coordinates = route['geometry']['coordinates'];
        setState(() {
          _route =
              coordinates
                  .map((coord) => LatLng(coord[1], coord[0]))
                  .cast<LatLng>()
                  .toList();
        });

        // Build directions text
        final directions = steps
            .map<String>((step) {
              return step['maneuver']['instruction'] ?? 'Continue';
            })
            .join('\n\n');

        setState(() {
          _directions = "Route to Blood Bank:\n\n$directions";
        });

        // Zoom to fit both points
        _mapController.fitBounds(
          LatLngBounds.fromPoints([origin, destination]),
          options: const FitBoundsOptions(padding: EdgeInsets.all(50)),
        );
      } else {
        setState(() {
          _directions = "No route found between these points";
          _route = [];
        });
      }
    } catch (e) {
      setState(() {
        _directions = "Error getting directions: ${e.toString()}";
        _route = [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _selectNearestBloodBank() {
    if (_currentPosition == null) return;

    // Find nearest blood bank using proper LatLng comparison
    LatLng nearest = _bloodBanks.reduce((a, b) {
      final distanceA = _distanceCalculator(_currentPosition!, a);
      final distanceB = _distanceCalculator(_currentPosition!, b);
      return distanceA < distanceB ? a : b;
    });

    setState(() {
      _selectedMarker = nearest;
    });

    // Get directions automatically
    _getDirections(_currentPosition!, nearest);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Bank Directions'),
        backgroundColor: Colors.redAccent,
        actions: [
          if (_currentPosition != null)
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: () {
                _mapController.move(_currentPosition!, 13.0);
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _currentPosition ?? _defaultLocation,
              zoom: 13.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedMarker = point;
                  _route = [];
                  _directions = "Tap 'Get Directions' to see route";
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  if (_currentPosition != null)
                    Marker(
                      point: _currentPosition!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.person_pin_circle,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                  ..._bloodBanks.map(
                    (bank) => Marker(
                      point: bank,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.local_hospital,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ),
                  if (_selectedMarker != null)
                    Marker(
                      point: _selectedMarker!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 50,
                      ),
                    ),
                ],
              ),
              PolylineLayer(
                polylines: [
                  if (_route.isNotEmpty)
                    Polyline(
                      points: _route,
                      strokeWidth: 4,
                      color: Colors.blue.withOpacity(0.7),
                    ),
                ],
              ),
            ],
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (_selectedMarker != null && _currentPosition != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                          ),
                          onPressed:
                              () => _getDirections(
                                _currentPosition!,
                                _selectedMarker!,
                              ),
                          icon: const Icon(Icons.directions),
                          label: const Text("Get Directions"),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _selectNearestBloodBank,
                          icon: const Icon(Icons.near_me),
                          label: const Text("Nearest Bank"),
                        ),
                      ],
                    ),
                  ),
                if (_directions.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: SingleChildScrollView(
                      child: Text(
                        _directions,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
