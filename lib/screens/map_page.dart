import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final double lat = args['lat'];
    final double lng = args['lng'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sender Location'),
        backgroundColor: Colors.redAccent,
      ),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng(lat, lng),
          zoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.your_app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                width: 60.0,
                height: 60.0,
                point: LatLng(lat, lng),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }
}
